//
//  ContentView.swift
//  AnimatedList
//
//  Created by Afeez Yunus on 12/02/2026.
//

import SwiftUI
import RiveRuntime
import CoreImage

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
                VStack(spacing: 12) {
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
        .ignoresSafeArea(edges:.bottom)
        .preferredColorScheme(.light)
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
    @State var disIntegrate = RiveViewModel(fileName: "disintegrate", stateMachineName: "Main", fit: .contain, alignment: .centerLeft)
    @State var disIntegrate2 = RiveViewModel(fileName: "disintegrate", stateMachineName: "Main", fit: .contain, alignment: .centerLeft)
    @State var disIntegrateImage = RiveViewModel(fileName: "disintegrate", stateMachineName: "Main", fit: .contain, alignment: .center)
    @State var effectInstance: RiveDataBindingViewModel.Instance?
    @State var effectInstance2: RiveDataBindingViewModel.Instance?
    @State var effectInstanceImage: RiveDataBindingViewModel.Instance?
    @State private var offset: CGFloat = 0
    @State private var lastOffset: CGFloat = 0
    @State private var isDeleting = false
    @State private var hideDeleteButton = false
    @State private var inactivityTask: Task<Void, Never>?
    @State var isSetUp = false
    @State var text1Opacity: Double = 1.0
    @State var text2Opacity: Double = 1.0
    @State var imageOpacity: Double = 1.0
    @State var albumColor: Color = .gray
    // Text size properties
    @State private var titleWidth: CGFloat = 0
    @State private var titleHeight: CGFloat = 0
    @State private var metadataWidth: CGFloat = 0
    @State private var metadataHeight: CGFloat = 0
    @State private var imageWidth: CGFloat = 44
    @State private var imageHeight: CGFloat = 54
    
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
                        
                        // Staggered disintegration effects
                        // Image first (after 0.3s)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            effectInstanceImage?.triggerProperty(fromPath: "delete")?.trigger()
                            withAnimation {
                                imageOpacity = 0
                            }
                        }
                        
                        // Title next (after 0.45s)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                            effectInstance?.triggerProperty(fromPath: "delete")?.trigger()
                            withAnimation {
                                text1Opacity = 0
                            }
                        }
                        
                        // Metadata last (after 0.6s)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            effectInstance2?.triggerProperty(fromPath: "delete")?.trigger()
                            withAnimation {
                                text2Opacity = 0
                            }
                        }
                        
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
            ZStack{
            HStack(spacing: 16) {
                // Album artwork
                ZStack {
                    Image(song.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 54)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .opacity(imageOpacity)
                        .onAppear {
                            extractAlbumColor()
                        }
                    disIntegrateImage.view()
                        .onAppear{
                            disIntegrateImage.setInput("canvasHeight", value: imageHeight)
                            disIntegrateImage.setInput("canvasWidth", value: imageWidth * 2)
                        }
                      .frame(width: imageWidth, height: imageHeight)
                }
                
                // Song info
                VStack(alignment: .leading, spacing: 4) {
                    ZStack(alignment:.leading){
                        Text(song.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color("primaryText"))
                            .lineLimit(1)
                            .opacity(text1Opacity)
                            .padding(.top, 4)
                            .background(
                                GeometryReader { geometry in
                                    Color.clear
                                        .onAppear{
                                            titleWidth = geometry.size.width
                                            titleHeight = geometry.size.height
                                            disIntegrate.setInput("canvasHeight", value: titleHeight * 2)
                                            disIntegrate.setInput("canvasWidth", value: titleWidth * 4)
                                            setupBind()
                                        }
                                }
                            )
                        disIntegrate.view()
                            .padding(.top, 4)
                        
                    }
                    
                    ZStack(alignment: .leading) {
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
                        .opacity(text2Opacity)
                        .padding(.bottom, 9)
                        .background(
                            GeometryReader { geometry in
                                Color.clear
                                    .onAppear{
                                        metadataWidth = geometry.size.width
                                        metadataHeight = geometry.size.height
                                        disIntegrate2.setInput("canvasHeight", value: metadataHeight)
                                        disIntegrate2.setInput("canvasWidth", value: metadataWidth * 2)
                                    }
                            }
                        )
                        
                        disIntegrate2.view()
                            .padding(.bottom, 9)
                    }
                }
                
                Spacer()
            }
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
    private func setupBind() {
        let effectVm = disIntegrate.riveModel?.riveFile.viewModelNamed("mainVm")
        effectInstance = effectVm?.createInstance(fromName: "Instance")
        disIntegrate.riveModel?.stateMachine?.bind(viewModelInstance: effectInstance!)
        
        let effectVm2 = disIntegrate2.riveModel?.riveFile.viewModelNamed("mainVm")
        effectInstance2 = effectVm2?.createInstance(fromName: "Instance")
        disIntegrate2.riveModel?.stateMachine?.bind(viewModelInstance: effectInstance2!)
        
        let effectVmImage = disIntegrateImage.riveModel?.riveFile.viewModelNamed("mainVm")
        effectInstanceImage = effectVmImage?.createInstance(fromName: "Instance")
        disIntegrateImage.riveModel?.stateMachine?.bind(viewModelInstance: effectInstanceImage!)
        
        // Set colors for all effects
        updateEffectColor(for: effectInstance, color: Color("primaryText"))       // Title color
        updateEffectColor(for: effectInstance2, color: Color("secondaryText"))    // Metadata color
        updateEffectColor(for: effectInstanceImage, color: albumColor)            // Album color
        
        isSetUp = true
        print("setup complete")
        updateEffect()
    }
    private func updateEffect() {
        guard titleWidth > 0, titleHeight > 0 else {
            print("Waiting for dimensions - titleWidth: \(titleWidth), titleHeight: \(titleHeight)")
            return
        }
        
        // Update title effect (first line)
        updateCanvasDimensions(for: effectInstance, width: titleWidth * 3.5, height: titleHeight * 4)
        updateEffectColor(for: effectInstance, color: Color("primaryText"))
        
        // Update metadata effect (second line)
        if metadataWidth > 0 && metadataHeight > 0 {
            updateCanvasDimensions(for: effectInstance2, width: metadataWidth * 3.5, height: metadataHeight * 4)
            updateEffectColor(for: effectInstance2, color: Color("secondaryText"))
        }
        
        // Update image effect with album color
        updateCanvasDimensions(for: effectInstanceImage, width: imageWidth * 1.5, height: imageHeight * 1.5 )
        updateEffectColor(for: effectInstanceImage, color: albumColor)
        
        disIntegrate.triggerInput("advance")
        print("Canvas updated - Title: [\(titleWidth) × \(titleHeight)], Metadata: [\(metadataWidth) × \(metadataHeight)], Image: [\(imageWidth) × \(imageHeight)]")
    }
    
    private func updateCanvasDimensions(for instance: RiveDataBindingViewModel.Instance?, width: CGFloat, height: CGFloat) {
        guard let instance else { return }
        instance.numberProperty(fromPath: "canvasWidth")?.value = Float(width)
        instance.numberProperty(fromPath: "canvasHeight")?.value = Float(height)
    }
    
    private func updateEffectColor(for instance: RiveDataBindingViewModel.Instance?, color: Color) {
        guard let instance else {
            print("⚠️ Cannot update color: instance is nil")
            return
        }
        
        // Convert SwiftUI Color to UIColor
        let uiColor = UIColor(color)
        
        // Extract RGB values for debugging
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        print("🎨 Attempting to set endColor - RGB(\(Int(red * 255)), \(Int(green * 255)), \(Int(blue * 255)), alpha: \(Int(alpha * 255)))")
        
        // Check if the color property exists
        if let colorProperty = instance.colorProperty(fromPath: "endColor") {
            colorProperty.value = uiColor
            print("✅ Successfully set endColor property")
            
            // Verify it was set
            if let verifyColor = colorProperty.value as? UIColor {
                var vr: CGFloat = 0, vg: CGFloat = 0, vb: CGFloat = 0, va: CGFloat = 0
                verifyColor.getRed(&vr, green: &vg, blue: &vb, alpha: &va)
                print("✅ Verified endColor is now: RGB(\(Int(vr*255)), \(Int(vg*255)), \(Int(vb*255)))")
            }
        } else {
            print("❌ Failed to find 'endColor' property in Rive instance")
            print("   Available properties might need to be checked in Rive file")
        }
    }
    
    private func cancelInactivityTimer() {
        inactivityTask?.cancel()
        inactivityTask = nil
    }
    
    private func extractAlbumColor() {
        guard let uiImage = UIImage(named: song.imageName) else {
            print("❌ Failed to load image: \(song.imageName)")
            return
        }
        
        print("🎨 Starting color extraction for: \(song.imageName)")
        
        DispatchQueue.global(qos: .userInitiated).async {
            let color = uiImage.averageColor()
            
            DispatchQueue.main.async {
                if let color = color {
                    self.albumColor = Color(color)
                    
                    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                    color.getRed(&r, green: &g, blue: &b, alpha: &a)
                    print("✅ Extracted album color for \(self.song.title): RGB(\(Int(r*255)), \(Int(g*255)), \(Int(b*255)))")
                    
                    // Update the effect color after extraction if instance is ready
                    if self.effectInstanceImage != nil {
                        print("🔧 Updating effect instance with extracted color...")
                        self.updateEffectColor(for: self.effectInstanceImage, color: self.albumColor)
                    } else {
                        print("⚠️ Effect instance not ready yet, color will be set on next update")
                    }
                } else {
                    print("❌ Failed to extract color from image")
                }
            }
        }
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

// MARK: - Color Extraction Extension
extension UIImage {
    func averageColor() -> UIColor? {
        guard let inputImage = CIImage(image: self) else { return nil }
        
        let extentVector = CIVector(x: inputImage.extent.origin.x,
                                     y: inputImage.extent.origin.y,
                                     z: inputImage.extent.size.width,
                                     w: inputImage.extent.size.height)
        
        guard let filter = CIFilter(name: "CIAreaAverage",
                                     parameters: [kCIInputImageKey: inputImage,
                                                 kCIInputExtentKey: extentVector]) else { return nil }
        guard let outputImage = filter.outputImage else { return nil }
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull as Any])
        context.render(outputImage,
                      toBitmap: &bitmap,
                      rowBytes: 4,
                      bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                      format: .RGBA8,
                      colorSpace: nil)
        
        return UIColor(red: CGFloat(bitmap[0]) / 255,
                      green: CGFloat(bitmap[1]) / 255,
                      blue: CGFloat(bitmap[2]) / 255,
                      alpha: CGFloat(bitmap[3]) / 255)
    }
}

// PreferenceKey for text size measurement
struct TextSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

struct MetadataSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}


