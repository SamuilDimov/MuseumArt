import Foundation

struct Painting {
    var imagePath: String
    var name: String
    var label: String
}

class CSVParser {
    static func parseCSV(from csvName: String) -> [Painting]? {
        guard let filePath = Bundle.main.path(forResource: csvName, ofType: "csv") else { return nil }
        var paintings: [Painting] = []

        do {
            let data = try String(contentsOfFile: filePath, encoding: .utf8)
            let rows = data.components(separatedBy: "\n")
            
            for row in rows {
                let columns = row.components(separatedBy: ",")
                if columns.count == 3 {
                    let painting = Painting(imagePath: columns[0], name: columns[1], label: columns[2])
                    paintings.append(painting)
                }
            }
        } catch {
            print(error)
            return nil
        }
        
        return paintings
    }
}
