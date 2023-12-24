//
//  ContentView.swift
//  iconvert
//
//  Created by jxhug on 12/23/23.
//

import SwiftUI
import UniformTypeIdentifiers
import AlertToast

struct IconsetSize {
    var width: Int
    var scale: Int
    
    init(_ width: Int, _ scale: Int) {
        self.width = width
        self.scale = scale
    }
}

struct ContentView: View {
    
    @State var originalImage: URL?
    
    @State var outputDir: URL?
    
    let validImageTypes: [String] = [
        "jpeg",
        "heic",
        "png",
        "tiff",
        "icns",
        "bmp",
        "gif",
        "pdf",
        "psd"
    ]
    
    let iconsetSizes: [IconsetSize] = [
        IconsetSize(16, 1),
        IconsetSize(16, 2),
        IconsetSize(32, 1),
        IconsetSize(32, 2),
        IconsetSize(128, 1),
        IconsetSize(128, 2),
        IconsetSize(256, 1),
        IconsetSize(256, 2),
        IconsetSize(512, 1),
        IconsetSize(512, 2)
    ]
    
    var items: [GridItem] = Array(repeating: .init(.adaptive(minimum: 120)), count: 3)
    
    @State var imageType: String = ""
    
    @State var isImporting: Bool = false
    
    @State var importType: [UTType] = [.image]
    
    @State var convertingImage: Bool = false
    
    @State var showToast: Bool = false
    
    @State var success: Bool = true
    
    @State var output: String = ""
    
    @State var errorSubstring: String = ""
    
    var body: some View {
        VStack(spacing: 30) {
            HStack(spacing: 20) {
                Button(action: {
                    importType = [.image]
                    isImporting.toggle()
                }) {
                    if let originalImage = originalImage {
                        if let image = NSImage(contentsOf: originalImage) {
                            Image(nsImage: image)
                                .resizable()
                                .scaledToFit()
                        } else {
                            Text("Failed to load image")
                        }
                    } else {
                        VStack(spacing: 20) {
                            Text("input image")
                                .opacity(0.6)
                                .font(.system(size: 30, weight: .semibold))
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .opacity(0.6)
                        }
                        .padding()
                    }
                }
                .focusable(false)
                .buttonStyle(.plain)
                .frame(width: 300, height: 300)
                .background(Color.gray.opacity(0.15))
                .cornerRadius(30)
                VStack(spacing: 20) {
                    Button(action: {
                        importType = [.folder]
                        isImporting.toggle()
                    }) {
                        if let outputDir = outputDir {
                            Text(outputDir.relativePath)
                                .opacity(0.6)
                                .font(.title2)
                                .padding()
                        } else {
                            HStack {
                                Text("output folder")
                                    .opacity(0.6)
                                    .font(.system(size: 20, weight: .medium))
                                Image(systemName: "folder")
                                    .opacity(0.6)
                                    .font(.system(size: 25, weight: .medium))
                            }
                            .padding()
                        }
                    }
                    .focusable(false)
                    .buttonStyle(.plain)
                    .frame(width: 300, height: 140)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(30)
                    
                    VStack {
                        LazyVGrid(columns: items) {
                            ForEach(validImageTypes, id: \.self) { type in
                                Button(action: {
                                    imageType = type
                                }) {
                                    Text(type)
                                        .fontWeight(.medium)
                                        .opacity(0.6)
                                        .font(.system(size: 17))
                                }
                                .buttonStyle(.plain)
                                .frame(width: 90, height: 40)
                                .background(imageType == type ? Color.gray.opacity(0.5) : Color.gray.opacity(0.15))
                                .cornerRadius(30)
                                .focusable(false)
                            }
                        }
                        .frame(width: 300, height: 140)
                    }

                }
            }
            if originalImage != nil && outputDir != nil && imageType != "" {
                Button(action: {
                    print("convert")
                    convertingImage.toggle()
                    convertIntoIcns()
                }) {
                    HStack(alignment: .center) {
                        if #available(macOS 14, *) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundColor(Color.white)
                                .font(.system(size: 25, weight: .bold))
                                .symbolEffect(.bounce, value: convertingImage)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundColor(Color.white)
                                .font(.system(size: 25, weight: .bold))
                        }
                        Text("convert")
                            .foregroundColor(Color.white)
                            .font(.system(size: 25, weight: .medium))
                    }
                }
                .buttonStyle(.plain)
                .frame(width: 300, height: 2/3 * 100)
                .background(Color.accentColor)
                .focusable(false)
                .cornerRadius(30)
            }
        }
        .frame(minWidth: 650, minHeight: 425)
        .padding(30)
        .fileImporter(isPresented: $isImporting, allowedContentTypes: importType) { result in
            do {
                if importType == [.image] {
                    originalImage = try result.get().absoluteURL
                } else if importType == [.folder] {
                    outputDir = try result.get().absoluteURL
                }
            }
            catch {
                print("Failed to get URL from file: \(error.localizedDescription)")
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Text("hi")
                    .hidden()
            }
        }
        .toast(isPresenting: $showToast) {
            AlertToast(type: success ? .complete(.green) : .error(.red), title: success ? "Conversion Completed!" : "Conversion Failed.", subTitle: success ? nil : errorSubstring)
        }
    }
    
    func convertIntoIcns() {
        if let originalImage = originalImage, let outputDir = outputDir {
            var command: String = ""
            if imageType == "icns" {
                //create iconset directory
                _ = shell("mkdir \"\(FileManager.default.temporaryDirectory.path)/\(originalImage.deletingPathExtension().lastPathComponent).iconset/\"")
                for size in iconsetSizes {
                    let tempCommand = "sips -s format png -z \(size.width * size.scale) \(size.width * size.scale) \"\(originalImage.path)\" -o \"\(FileManager.default.temporaryDirectory.path)/\(originalImage.deletingPathExtension().lastPathComponent).iconset/icon_\(size.width)x\(size.width)\(size.scale != 1 ? "@2x" : "").png\""
                    let uh = shell(tempCommand)
                    print(uh)
                }
                command = "iconutil -c icns \"\(FileManager.default.temporaryDirectory.path)/\(originalImage.deletingPathExtension().lastPathComponent).iconset/\" -o \"\(outputDir.path)/\(originalImage.deletingPathExtension().lastPathComponent).icns/\"; rm -r \"\(FileManager.default.temporaryDirectory.path)/\(originalImage.deletingPathExtension().lastPathComponent).iconset/\""
            } else {
                command = "sips -s format \(imageType) \"\(originalImage.path)\" -o \"\(outputDir.path)\""
            }
            print(command)
            output = shell(command)
            
            let regex = try! NSRegularExpression(pattern: "Error \\d+:.*")
            let range = NSRange(output.startIndex..<output.endIndex, in: output)

            if let match = regex.firstMatch(in: output, options: [], range: range) {
                errorSubstring = String(output[Range(match.range, in: output)!])
                success = false
            } else {
                success = true
            }

            showToast.toggle()
        }
    }
}



func shell(_ command: String) -> String {
    let task = Process()
    let pipe = Pipe()
    
    task.standardOutput = pipe
    task.standardError = pipe
    task.arguments = ["-c", command]
    task.launchPath = "/bin/zsh"
    task.standardInput = nil
    task.launch()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)!
    print(output)
    return output
}

#Preview {
    ContentView()
}
