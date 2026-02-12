//
//  ContentView.swift
//  AnimatedList
//
//  Created by Afeez Yunus on 12/02/2026.
//

import SwiftUI
import RiveRuntime

struct ContentView: View {
    @State var searchText: String = ""
    @State var selectedTab: String = "Saved"
    @State var songs: [Song] = Song.sampleSongs
    @State var activeSwipeID: UUID? = nil
    
    let tabs = ["Saved", "For You", "Trending"]
    
    var body: some View {
        VStack {
            HStack{
                HStack{
                    Image(systemName: "magnifyingglass")
                        .imageScale(.large)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color("primaryText"))
                    TextField("Search songs, users or playlists", text: $searchText)
                        .font(.subheadline)
                        .foregroundStyle(Color("disabledText"))
                }
                .padding(.vertical)
                .padding(.horizontal, 24)
                .background(Color("secondaryBg"))
                .clipShape(Capsule())
                Image(systemName: "xmark")
                    .foregroundStyle(Color("primaryText"))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(20)
                    .background(Color("secondaryBg"))
                    .clipShape(Circle())
            }
            HStack{
                HStack (spacing:16){
                    ForEach(tabs, id: \.self) { tab in
                        TabItem(title: tab, isSelected: selectedTab == tab)
                            .onTapGesture {
                                selectedTab = tab
                            }
                    }
                }
                Spacer()
            }
            .padding(.top)
            .padding(.horizontal, 8)
            
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(songs) { song in
                        SongRow(
                            song: song,
                            isActive: activeSwipeID == song.id,
                            onSwipeChanged: { isOpen in
                                if isOpen {
                                    activeSwipeID = song.id
                                } else if activeSwipeID == song.id {
                                    activeSwipeID = nil
                                }
                            },
                            onDelete: {
                                deleteSong(song)
                            }
                        )
                    }
                }
                .padding(.top)
            }.scrollIndicators(.hidden)
        }
        .padding()
        .background(
            Color("BackgroundColor")
        )
    }
    
    func deleteSong(_ song: Song) {
        // Delay deletion by 1 second
        Task {
            try? await Task.sleep(for: .seconds(1))
            await MainActor.run {
                // Clear the active swipe first
                if activeSwipeID == song.id {
                    activeSwipeID = nil
                }
                // Then delete with animation
                // Customize the animation here:
                withAnimation(.spring(response: 0.4)) {
                    songs.removeAll { $0.id == song.id }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

struct SongRow: View {
    let song: Song
    let isActive: Bool
    let onSwipeChanged: (Bool) -> Void
    let onDelete: () -> Void
    
    @State private var offset: CGFloat = 0
    @State private var lastOffset: CGFloat = 0
    @State private var isDeleting = false
    @State private var hideDeleteButton = false
    @State private var inactivityTask: Task<Void, Never>?
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete button background - only show when not deleting and offset < 0
            if !hideDeleteButton && offset < 0 {
                HStack {
                    Spacer()
                    Button(action: {
                        isDeleting = true
                        cancelInactivityTimer()
                        
                        // Close the swipe immediately with animation
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            offset = 0
                            lastOffset = 0
                        }
                        onSwipeChanged(false)
                        
                        // Delay hiding the delete button
                        Task {
                            try? await Task.sleep(for: .seconds(0.15))
                            await MainActor.run {
                                hideDeleteButton = true
                            }
                        }
                        
                        onDelete()
                    }) {
                        Image(systemName: "trash")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .frame(width: 80)
                    }
                }
                .frame(height: 54)
                .background(Color.red)
            }
            
            // Song content
            HStack(spacing: 16) {
                // Album artwork
                Image(song.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 54)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Song info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(song.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color("primaryText"))
                            .lineLimit(1)
                    }
                    
                    HStack(spacing: 4) {
                        Text(song.artist)
                        Text("·")
                        Text("\(song.reels) reels")
                        Text("·")
                        Text(song.duration)
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color("secondaryText"))
                    .lineLimit(1)
                }
                
                Spacer()
            }
            .padding(.horizontal, 4)
        
            .background(Color("BackgroundColor"))
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        // Don't allow swiping if deleting
                        guard !isDeleting else { return }
                        
                        cancelInactivityTimer()
                        
                        let translation = gesture.translation.width
                        let newOffset = lastOffset + translation
                        
                        // Only allow swiping left (negative offset)
                        if newOffset < 0 {
                            // Apply resistance when trying to go beyond -80
                            if newOffset < -80 {
                                // Resistance effect - gets harder to pull
                                let excess = newOffset + 80
                                offset = -80 + (excess * 0.2)
                            } else {
                                offset = newOffset
                            }
                        } else {
                            // Don't allow positive offset (swiping right when closed)
                            offset = 0
                        }
                    }
                    .onEnded { gesture in
                        // Don't respond to gesture if deleting
                        guard !isDeleting else { return }
                        
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            // If offset is less than -40, snap to open position
                            if offset < -40 {
                                offset = -80
                                lastOffset = -80
                                onSwipeChanged(true)
                                startInactivityTimer()
                            } else {
                                // Otherwise close it
                                offset = 0
                                lastOffset = 0
                                onSwipeChanged(false)
                            }
                        }
                    }
            )
          //  .opacity(isDeleting ? 0.5 : 1.0)
        }
        .onChange(of: isActive) { oldValue, newValue in
            // Close this row if another row becomes active (but not during deletion)
            if !newValue && offset < 0 && !isDeleting {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    offset = 0
                    lastOffset = 0
                }
                cancelInactivityTimer()
            }
        }
    }
    
    private func startInactivityTimer() {
        cancelInactivityTimer()
        
        inactivityTask = Task {
            try? await Task.sleep(for: .seconds(2))
            
            // Check if task was cancelled
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    offset = 0
                    lastOffset = 0
                    onSwipeChanged(false)
                }
            }
        }
    }
    
    private func cancelInactivityTimer() {
        inactivityTask?.cancel()
        inactivityTask = nil
    }
}

struct TabItem: View {
    let title: String
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .medium)
                .foregroundStyle(isSelected ? Color("primaryText") : Color("secondaryText"))
            Rectangle()
                .fill(isSelected ? Color("primaryText"): .clear)
                .frame(height: 2)
        }
        .fixedSize()
    }
}


