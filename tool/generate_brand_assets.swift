import AppKit

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
let ivory = CGColor(colorSpace: colorSpace, components: [243 / 255, 238 / 255, 231 / 255, 1])!
let blue = CGColor(colorSpace: colorSpace, components: [69 / 255, 102 / 255, 214 / 255, 1])!

func png(_ size: Int, icon: Bool = true, desktop: Bool = false, launch: Bool = true) -> Data {
    let alpha: CGImageAlphaInfo = icon && !desktop ? .noneSkipLast : .premultipliedLast
    let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
        bytesPerRow: size * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: alpha.rawValue)!
    context.scaleBy(x: CGFloat(size) / 1024, y: CGFloat(size) / 1024)
    context.translateBy(x: 0, y: 1024)
    context.scaleBy(x: 1, y: -1)
    if icon {
        context.setFillColor(ivory)
        if desktop {
            context.addPath(CGPath(roundedRect: CGRect(x: 72, y: 72, width: 880, height: 880),
                cornerWidth: 196, cornerHeight: 196, transform: nil))
            context.fillPath()
        } else {
            context.fill(CGRect(x: 0, y: 0, width: 1024, height: 1024))
        }
    } else if launch {
        context.translateBy(x: -256, y: -256)
        context.scaleBy(x: 1.5, y: 1.5)
    }
    let pocket = CGMutablePath()
    pocket.move(to: CGPoint(x: 302, y: 294))
    pocket.addLine(to: CGPoint(x: 722, y: 294))
    pocket.addLine(to: CGPoint(x: 722, y: 566))
    pocket.addCurve(to: CGPoint(x: 512, y: 770), control1: CGPoint(x: 722, y: 690), control2: CGPoint(x: 612, y: 734))
    pocket.addCurve(to: CGPoint(x: 302, y: 566), control1: CGPoint(x: 412, y: 734), control2: CGPoint(x: 302, y: 690))
    pocket.closeSubpath()
    context.setFillColor(blue)
    context.addPath(pocket)
    context.fillPath()
    context.setStrokeColor(ivory)
    context.setLineWidth(14)
    context.setLineCap(.round)
    context.move(to: CGPoint(x: 348, y: 345))
    context.addLine(to: CGPoint(x: 676, y: 345))
    context.strokePath()
    let note = CGMutablePath()
    note.move(to: CGPoint(x: 523, y: 431))
    note.addLine(to: CGPoint(x: 624, y: 406))
    note.addLine(to: CGPoint(x: 624, y: 454))
    note.addLine(to: CGPoint(x: 555, y: 472))
    note.addLine(to: CGPoint(x: 555, y: 591))
    note.addCurve(to: CGPoint(x: 486, y: 636), control1: CGPoint(x: 555, y: 618), control2: CGPoint(x: 524, y: 640))
    note.addCurve(to: CGPoint(x: 481, y: 557), control1: CGPoint(x: 425, y: 631), control2: CGPoint(x: 430, y: 569))
    note.addCurve(to: CGPoint(x: 523, y: 558), control1: CGPoint(x: 499, y: 552), control2: CGPoint(x: 512, y: 553))
    note.closeSubpath()
    context.setFillColor(ivory)
    context.addPath(note)
    context.fillPath()
    let data = NSBitmapImageRep(cgImage: context.makeImage()!).representation(using: .png, properties: [:])!
    let result = NSBitmapImageRep(data: data)!
    precondition(result.pixelsWide == size && result.pixelsHigh == size)
    precondition(!icon || desktop || !result.hasAlpha)
    return data
}

func save(_ data: Data, _ path: String) throws {
    let url = root.appendingPathComponent(path)
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try data.write(to: url)
}

for platform in ["ios", "macos"] {
    let folder = "\(platform)/Runner/Assets.xcassets/AppIcon.appiconset"
    let data = try Data(contentsOf: root.appendingPathComponent("\(folder)/Contents.json"))
    let catalog = try JSONSerialization.jsonObject(with: data) as! [String: Any]
    for entry in catalog["images"] as! [[String: String]] {
        let size = Double(entry["size"]!.components(separatedBy: "x")[0])!
        let scale = Double(entry["scale"]!.dropLast())!
        try save(png(Int(size * scale), desktop: platform == "macos"), "\(folder)/\(entry["filename"]!)")
    }
}
try save(png(1024), "assets/icons/app_icon.png")
try save(png(360, icon: false), "assets/icons/launch_mark.png")
for scale in 1...3 {
    let suffix = scale == 1 ? "" : "@\(scale)x"
    try save(png(120 * scale, icon: false), "ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage\(suffix).png")
}
for (density, size) in [("mdpi", 48), ("hdpi", 72), ("xhdpi", 96), ("xxhdpi", 144), ("xxxhdpi", 192)] {
    try save(png(size), "android/app/src/main/res/mipmap-\(density)/ic_launcher.png")
    try save(png(size * 5 / 2, icon: false), "android/app/src/main/res/drawable-\(density)/launch_mark.png")
    try save(png(size * 6, icon: false, launch: false), "android/app/src/main/res/drawable-\(density)/splash_icon.png")
}
for size in [192, 512] {
    try save(png(size), "web/icons/Icon-\(size).png")
    try save(png(size), "web/icons/Icon-maskable-\(size).png")
}
try save(png(32), "web/favicon.png")

func littleEndian<T: FixedWidthInteger>(_ value: T) -> Data {
    var value = value.littleEndian
    return withUnsafeBytes(of: &value) { Data($0) }
}
let sizes = [16, 24, 32, 48, 64, 128, 256]
var ico = littleEndian(UInt16(0)) + littleEndian(UInt16(1)) + littleEndian(UInt16(sizes.count))
var payload = Data()
for size in sizes {
    let data = png(size, desktop: true)
    ico.append(contentsOf: [UInt8(size % 256), UInt8(size % 256), 0, 0])
    ico.append(littleEndian(UInt16(1)))
    ico.append(littleEndian(UInt16(32)))
    ico.append(littleEndian(UInt32(data.count)))
    ico.append(littleEndian(UInt32(6 + sizes.count * 16 + payload.count)))
    payload.append(data)
}
ico.append(payload)
try save(ico, "windows/runner/resources/app_icon.ico")
print("Generated Music Pocket icons and launch marks.")
