import Foundation

enum HomeTab: String, CaseIterable, CustomStringConvertible, Identifiable {
    case finance = "금융"
    case novels = "소설"
    case photoVideo = "사진/비디오"
    case games = "게임"
    case entertainment = "엔터테인먼트"
    case shopping = "쇼핑"
    case healthFitness = "건강/피트니스"
    case productivity = "생산성"
    case education = "교육"
    case music = "음악"

    var id: Self { self }
    var description: String { rawValue }

    var genreId: Int {
        switch self {
        case .finance:
            return 6015
        case .novels:
            return 6005
        case .photoVideo:
            return 6008
        case .games:
            return 6014
        case .entertainment:
            return 6016
        case .shopping:
            return 6024
        case .healthFitness:
            return 6013
        case .productivity:
            return 6007
        case .education:
            return 6017
        case .music:
            return 6011
        }
    }

    var term: String {
        switch self {
        case .finance:
            return "finance"
        case .novels:
            return "novel"
        case .photoVideo:
            return "photo"
        case .games:
            return "game"
        case .entertainment:
            return "entertainment"
        case .shopping:
            return "shopping"
        case .healthFitness:
            return "health"
        case .productivity:
            return "productivity"
        case .education:
            return "education"
        case .music:
            return "music"
        }
    }
}
