import Foundation

enum Endpoint {
    case login
    case health
    case cars
    case car(id: Int)
    case carSummary(carId: Int)
    case drives(carId: Int, page: Int, perPage: Int)
    case drive(id: Int)
    case driveGpx(id: Int)
    case charges(carId: Int, page: Int, perPage: Int)
    case charge(id: Int)
    case positions(carId: Int, page: Int, perPage: Int)

    // Stats endpoints
    case batteryHealth(carId: Int, from: String?, to: String?)
    case projectedRange(carId: Int, from: String?, to: String?)
    case chargeLevel(carId: Int, from: String?, to: String?)
    case vampireDrain(carId: Int, from: String?, to: String?)
    case driveStats(carId: Int, from: String?, to: String?, bucket: String?)
    case efficiency(carId: Int, from: String?, to: String?)
    case mileage(carId: Int, from: String?, to: String?, bucket: String?)
    case visitedHeatmap(carId: Int, from: String?, to: String?)
    case visitedRoutes(carId: Int, from: String?, to: String?, limit: Int?)
    case visitedPlaces(carId: Int, from: String?, to: String?)
    case chargingStats(carId: Int, from: String?, to: String?, bucket: String?)
    case dcCurve(carId: Int, from: String?, to: String?)
    case states(carId: Int, from: String?, to: String?)
    case timeline(carId: Int, from: String?, to: String?, page: Int, perPage: Int)
    case updates(carId: Int, from: String?, to: String?)

    var path: String {
        switch self {
        case .login:
            return "/api/v1/auth/login"
        case .health:
            return "/api/v1/health"
        case .cars:
            return "/api/v1/cars"
        case .car(let id):
            return "/api/v1/cars/\(id)"
        case .carSummary(let carId):
            return "/api/v1/cars/\(carId)/summary"
        case .drives(let carId, let page, let perPage):
            return "/api/v1/cars/\(carId)/drives?page=\(page)&per_page=\(perPage)"
        case .drive(let id):
            return "/api/v1/drives/\(id)"
        case .driveGpx(let id):
            return "/api/v1/drives/\(id)/gpx"
        case .charges(let carId, let page, let perPage):
            return "/api/v1/cars/\(carId)/charges?page=\(page)&per_page=\(perPage)"
        case .charge(let id):
            return "/api/v1/charges/\(id)"
        case .positions(let carId, let page, let perPage):
            return "/api/v1/cars/\(carId)/positions?page=\(page)&per_page=\(perPage)"
        case .batteryHealth(let carId, let from, let to):
            return "/api/v1/cars/\(carId)/stats/battery_health" + dateQuery(from: from, to: to)
        case .projectedRange(let carId, let from, let to):
            return "/api/v1/cars/\(carId)/stats/projected_range" + dateQuery(from: from, to: to)
        case .chargeLevel(let carId, let from, let to):
            return "/api/v1/cars/\(carId)/stats/charge_level" + dateQuery(from: from, to: to)
        case .vampireDrain(let carId, let from, let to):
            return "/api/v1/cars/\(carId)/stats/vampire_drain" + dateQuery(from: from, to: to)
        case .driveStats(let carId, let from, let to, let bucket):
            return "/api/v1/cars/\(carId)/stats/drives" + dateQuery(from: from, to: to, extra: bucket.map { ["bucket": $0] })
        case .efficiency(let carId, let from, let to):
            return "/api/v1/cars/\(carId)/stats/efficiency" + dateQuery(from: from, to: to)
        case .mileage(let carId, let from, let to, let bucket):
            return "/api/v1/cars/\(carId)/stats/mileage" + dateQuery(from: from, to: to, extra: bucket.map { ["bucket": $0] })
        case .visitedHeatmap(let carId, let from, let to):
            return "/api/v1/cars/\(carId)/stats/visited/heatmap" + dateQuery(from: from, to: to)
        case .visitedRoutes(let carId, let from, let to, let limit):
            return "/api/v1/cars/\(carId)/stats/visited/routes" + dateQuery(from: from, to: to, extra: limit.map { ["limit": "\($0)"] })
        case .visitedPlaces(let carId, let from, let to):
            return "/api/v1/cars/\(carId)/stats/visited/places" + dateQuery(from: from, to: to)
        case .chargingStats(let carId, let from, let to, let bucket):
            return "/api/v1/cars/\(carId)/stats/charging" + dateQuery(from: from, to: to, extra: bucket.map { ["bucket": $0] })
        case .dcCurve(let carId, let from, let to):
            return "/api/v1/cars/\(carId)/stats/charging/dc_curve" + dateQuery(from: from, to: to)
        case .states(let carId, let from, let to):
            return "/api/v1/cars/\(carId)/states" + dateQuery(from: from, to: to)
        case .timeline(let carId, let from, let to, let page, let perPage):
            return "/api/v1/cars/\(carId)/timeline" + dateQuery(from: from, to: to, extra: ["page": "\(page)", "per_page": "\(perPage)"])
        case .updates(let carId, let from, let to):
            return "/api/v1/cars/\(carId)/updates" + dateQuery(from: from, to: to)
        }
    }

    var method: String {
        switch self {
        case .login:
            return "POST"
        default:
            return "GET"
        }
    }

    func url(baseURL: String) -> URL? {
        URL(string: baseURL + path)
    }

    private func dateQuery(from: String? = nil, to: String? = nil, extra: [String: String]? = nil) -> String {
        var params: [String] = []
        if let from { params.append("from=\(from)") }
        if let to { params.append("to=\(to)") }
        if let extra {
            for (key, value) in extra {
                params.append("\(key)=\(value)")
            }
        }
        return params.isEmpty ? "" : "?" + params.joined(separator: "&")
    }
}
