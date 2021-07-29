//
//  NetworkManager.swift
//  WalletDemo
//
//  Created by LvesLi on 2021/7/21.
//

import Foundation
import Alamofire

// Card Activation info
struct VLCardActivationInfo: Decodable {
    var activationData: String?
    var encryptedPassData: String?
    var ephemeralPublicKey: String?
    var vCardID: String?
}


struct NetworkManager {
    //TODO: change url
    static let serverUrl: String = "http://192.168.208.86:8080/WebDemo_war_exploded/velo_visa"
    
    static func loadActivationInfo<R: Decodable>(card: CardInfo, certificate: Data, nonce: Data, nonceSignature: Data, completion: @escaping (R?, Bool) -> Void) {
        
        let params = [
            "accountNumber": card.accountNumber,
            "nameOnCard": card.nameOnCard,
            "cvv2": card.cvv2,
            "month": card.month,
            "year": card.year,
            "deviceCert": String(data: certificate, encoding: .utf8) ?? "",
            "nonceSignature": String(data: nonceSignature, encoding: .utf8) ?? "",
            "nonce":  String(data: nonce, encoding: .utf8) ?? ""]
        print("requset:\(params)\n", to: &Log.log)
        
        let request = AF.request(serverUrl, method: .post, parameters: params)
        
        request.responseJSON { response in
            debugPrint(response)
            print("response:\(response)\n", to: &Log.log)
            //TODO: mock data
//            let model: R? = convertToModel(json: MockData.json)
//            completion(model, true)
            switch response.result {
            case .success(let model):
                let model: R? = convertToModel(json: model)
                completion(model, true)
            case .failure(_):
                completion(nil, false)
            }
        }
        
    }
    
    static func convertToModel<R: Decodable>(json: Any) -> R? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: json , options: .prettyPrinted)
            let model = try JSONDecoder().decode(R.self, from: jsonData)
            return model
        } catch {}
        return nil
    }
}


struct MockData {
    static let json: [String: String] = [
        "activationData":"TUJQQUMtMS1GSy00MDEyMDAuMS0tVERFQS1CMEQwQjcxNDNFN0M1QTc3M0I5MTc1OTA3RENCMUEzRUNCRENCQjJEMzI2MDBEOEY4RTU5OEI5QzE4OTlGNzA3RjFCMDQ2RDY3RDNDREUwMg==",
        "encryptedPassData":"V3bICnkm37BmBKEF9FAKK2zh2SvLhe6PqjvJaHS2t0eJaKVL/SfQ8mXOkDN7o4h7ayFmSuBy7A4R9uYWqWdZbo7fc0xOcsQLCgwQdVkW90JHAgL6j9axg26+OxrWyo7T9qm6NBlZzQFAy1oqYmw1tq6QMAEfbv7W6omlZMojl7aJjvzETINq/YXY8Xp76hoMQFsNDpnNfFuAONmCaCm5Vd6a1zW4ULI0SC1OPo8SdiEULTtZQO1XwiMtbD31JkSUhvHAEP2uo9bEeytPQwr82u6lxzzjLhBP30JByQeOJ2y2o/k83XNGanZhlR1yojp9gObw6m/wyj/rfGxMFVhZtzDVFDblgp1NzvCkPx0iyMRTURGLLmzyrLpzwVGIqv39GorEesOL1KtHb15KuwCtawdej3QiL95rPRTW58stEr/PxLh3Bp9AjlV07tJTXdrKNz357j8hLo1AmRv2p8prnZDF0A0j3jn71P68kvwvWhvZ3F+R0sNuC+E16IV1sJrWIlChU4NvcmsLBsv+ewsFqqGquDlpbFc3LuCQhE9PUu6wEGa7Im4e+Cbk79tcg+ZYFS1X4W7sAWLlxM0JzTMWdzSkqydLjiVc9FvoM3gBFrm/1rs7I5CACNg0vyHpXDhPFTM3a9eysWef7qRdTxLIA7CUKDx59r4VTWtGijz1Pwb5uZCnYvZd3i/+T7ra4xZ+9Z6u/nCqfWkZxNTfEfc3NOXte8s=",
        "ephemeralPublicKey":"BBSV6JzHhqoS0pLO6xMV6Z5yRhoOnpxaLtdjHxb7pPXpmNGra65K3kvUnlwfRTkWjA7v2+rp+/sK/RhLqLdEGok=",
        "vCardID":"v-123-a90f0f6e-065a-42b7-82d9-394ac7237501"]
}
