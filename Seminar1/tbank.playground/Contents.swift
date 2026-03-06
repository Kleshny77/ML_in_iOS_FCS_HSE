import UIKit

class PostOfficeViewController: UIViewController {
 
    struct Mail {
        let message: String
        let date: Date
    }
 
    let networkService = NetworkService()
    let recipientId: String
 
    init(
        recipientId: String,
        messagesToSend: [String]
    ) {
        self.recipientId = recipientId
        super.init(nibName: nil, bundle: nil)
        sendMessages(messagesToSend)
    }
 
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
 
    func sendMessages(_ messages: [String]) {
        let package = messages.map { message in
            Mail(message: message, date: Date())
        }
        sendMailPackage(package)
    }
 
    func sendMailPackage(_ package: [Mail]) {
        var successfullySentMails = 0
        for mail in package {
            let payload = formatPayload(with: mail)
 
            networkService.sendMail(payload: payload, recipientId: recipientId) { response, error in
                if let error {
                    self.handleErrorOccurred(error)
                } else if response != nil {
                    successfullySentMails += 1
                }
            }
        }
 
        handleDeliveryFinish(successfullySentMails: successfullySentMails)
    }
 
    func formatPayload(with mail: Mail) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy HH:mm"
        let formattedDate = formatter.string(from: mail.date)
        return "\(formattedDate): \(mail.message)"
    }
 
    func handleErrorOccurred(_ error: Error) {
        /* Shows UIAlertController with error */
    }
 
    func handleDeliveryFinish(successfullySentMails: Int) {
        /* Shows number of successfully sent mails in UILabel */
    }
}
 
struct SuccessResponse: Decodable {
    /* Some decodable response fields... */
}
 
class NetworkService {
    func sendMail(
        payload: String,
        recipientId: String,
        completion: @escaping (SuccessResponse?, Error?) -> Void
    ) {
        guard let url = URL(string: "www.tbank.ru/sendMail?recipient=\(recipientId)") else { return }
 
        var request = URLRequest(url: url)
        if let data = payload.data(using: .utf8) {
            request.httpMethod = "POST"
            request.httpBody = data
        }
 
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                completion(nil, error)
            } else if let data {
                let response = try? JSONDecoder().decode(SuccessResponse.self, from: data)
                completion(response, nil)
            }
        }.resume()
    }
}

