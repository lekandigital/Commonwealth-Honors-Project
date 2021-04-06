import Foundation

public struct ReturnedDataObject: Codable {
    public var data: EmotionDataValues
}

// MARK: - DataClass
public struct EmotionDataValues: Codable {
    public var boundingBox: BoundingBox
    public var ageRange: AgeRange
    public var smile, eyeglasses, sunglasses: Beard
    public var gender: Gender
    public var beard, mustache, eyesOpen, mouthOpen: Beard
    public var emotions: [Emotion]
    public var landmarks: [Landmark]
    public var pose: Pose
    public var quality: Quality
    public var confidence: Double

    enum CodingKeys: String, CodingKey {
        case boundingBox = "BoundingBox"
        case ageRange = "AgeRange"
        case smile = "Smile"
        case eyeglasses = "Eyeglasses"
        case sunglasses = "Sunglasses"
        case gender = "Gender"
        case beard = "Beard"
        case mustache = "Mustache"
        case eyesOpen = "EyesOpen"
        case mouthOpen = "MouthOpen"
        case emotions = "Emotions"
        case landmarks = "Landmarks"
        case pose = "Pose"
        case quality = "Quality"
        case confidence = "Confidence"
    }
}

// MARK: - AgeRange
public struct AgeRange: Codable {
    public var low, high: Int

    enum CodingKeys: String, CodingKey {
        case low = "Low"
        case high = "High"
    }
}

// MARK: - Beard
public struct Beard: Codable {
    public var value: Bool
    public var confidence: Double

    enum CodingKeys: String, CodingKey {
        case value = "Value"
        case confidence = "Confidence"
    }
}

// MARK: - BoundingBox
public struct BoundingBox: Codable {
    public var width, height, boundingBoxLeft, top: Double

    enum CodingKeys: String, CodingKey {
        case width = "Width"
        case height = "Height"
        case boundingBoxLeft = "Left"
        case top = "Top"
    }
}

// MARK: - Emotion
public struct Emotion: Codable {
    public var type: String
    public var confidence: Double

    enum CodingKeys: String, CodingKey {
        case type = "Type"
        case confidence = "Confidence"
    }
}

// MARK: - Gender
public struct Gender: Codable {
    public var value: String
    public var confidence: Double

    enum CodingKeys: String, CodingKey {
        case value = "Value"
        case confidence = "Confidence"
    }
}

// MARK: - Landmark
public struct Landmark: Codable {
    public var type: String
    public var x, y: Double

    enum CodingKeys: String, CodingKey {
        case type = "Type"
        case x = "X"
        case y = "Y"
    }
}

// MARK: - Pose
public struct Pose: Codable {
    public var roll, yaw, pitch: Double

    enum CodingKeys: String, CodingKey {
        case roll = "Roll"
        case yaw = "Yaw"
        case pitch = "Pitch"
    }
}

// MARK: - Quality
public struct Quality: Codable {
    public var brightness, sharpness: Double

    enum CodingKeys: String, CodingKey {
        case brightness = "Brightness"
        case sharpness = "Sharpness"
    }
}
