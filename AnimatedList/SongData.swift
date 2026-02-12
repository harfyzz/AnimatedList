//
//  SongData.swift
//  AnimatedList
//
//  Created by Afeez Yunus on 12/02/2026.
//

import Foundation

struct Song: Identifiable {
    let id = UUID()
    let title: String
    let artist: String
    let reels: String
    let duration: String
    let imageName: String
    var hasIcon: Bool = false
}

extension Song {
    static let sampleSongs: [Song] = [
        Song(title: "Beautiful", artist: "SHYY BEATS", reels: "3.2M", duration: "2:16", imageName: "Beautiful"),
        Song(title: "Pink + White", artist: "Frank Ocean", reels: "681K", duration: "3:05", imageName: "Pink + White", hasIcon: true),
        Song(title: "Pretty Little Baby (Stereo Mix)", artist: "Connie Francis", reels: "155K", duration: "2:23", imageName: "Pretty Little Baby (Stereo Mix)"),
        Song(title: "Original audio", artist: "alexwaarren", reels: "120K", duration: "0:22", imageName: "Original audio"),
        Song(title: "BIRDS OF A FEATHER", artist: "Billie Eilish", reels: "2.5M", duration: "3:31", imageName: "BIRDS OF A FEATHER"),
        Song(title: "Oh My Angel", artist: "Bertha Tillman", reels: "70K", duration: "2:23", imageName: "Oh My Angel"),
        Song(title: "Beanie", artist: "Chezile", reels: "936K", duration: "2:13", imageName: "Beanie"),
        Song(title: "Ida Was Here", artist: "idaandu", reels: "98K", duration: "0:11", imageName: "Ida Was Here"),
        Song(title: "Mrs Magic", artist: "Strawberry Guy", reels: "309K", duration: "3:29", imageName: "Mrs Magic"),
        Song(title: "Good Days", artist: "SZA", reels: "1.2M", duration: "4:39", imageName: "Good Days")
    ]
}
