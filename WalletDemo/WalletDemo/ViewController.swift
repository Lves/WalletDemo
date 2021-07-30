//
//  ViewController.swift
//  WalletDemo
//
//  Created by LvesLi on 2021/7/20.
//

import UIKit
import PassKit

struct CardInfo {
    let accountNumber: String = "4761120010000492"//"4514234420053999"
    let nameOnCard: String = "Digital Issuance"
    let cvv2: String = "533"//"123"
    let month: String = "11"//"01"
    let year: String = "2022"//"2021"
}

class ViewController: UIViewController {
    var passController: PKAddPaymentPassViewController?
    var primaryAccountIdentifier: String?
    let currentCard: CardInfo = CardInfo()
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var numberTextField: UITextField!
    @IBOutlet weak var descTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nameTextField.text = "Tom"
        numberTextField.text = currentCard.accountNumber.last4Characters
        descTextField.text = "Credit Card (\(currentCard.accountNumber.last4Characters))"
        
        //TODO: bankname ???
        let result = PassKitCardDetector.checkSupportApplePay(cardSuffix: currentCard.accountNumber.last4Characters, bankName: "EastWestBank")
        
        switch result {
        case .enabled(let primaryAccountIdentifier):
            self.primaryAccountIdentifier = primaryAccountIdentifier
            let button = PKAddPassButton(addPassButtonStyle: .black)
            button.frame = CGRect(x: 100, y: 200, width: 300, height: 50)
            button.center = view.center
            button.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
            view.addSubview(button)
        default:
            break
        }
    }
    
    @objc func addTapped() {
        guard let config = PKAddPaymentPassRequestConfiguration(encryptionScheme: .ECC_V2) else { return }
        config.cardholderName  = nameTextField.text
        config.primaryAccountSuffix = numberTextField.text
        config.localizedDescription = descTextField.text
        config.paymentNetwork = .visa
        //optional
        config.primaryAccountIdentifier = self.primaryAccountIdentifier
        config.cardDetails = [PKLabeledValue(label: "title01", value: "value01")]
        
        let lib = PKPassLibrary()
        lib.openPaymentSetup()
        
        guard let passController = PKAddPaymentPassViewController(requestConfiguration: config, delegate: self) else { return }
        present(passController, animated: true, completion: nil)
    }
}


extension ViewController: PKAddPaymentPassViewControllerDelegate {
    
    func addPaymentPassViewController(_ controller: PKAddPaymentPassViewController, generateRequestWithCertificateChain certificates: [Data], nonce: Data, nonceSignature: Data, completionHandler handler: @escaping (PKAddPaymentPassRequest) -> Void) {
        var str: String = ""
        certificates.forEach({ str = str.appending("Cent: \( $0.base64EncodedString())\n")})
        
        print("Delegate：\(str)\n\nNonce:\(nonce.base64EncodedString())\n\nNonceSignature:\(nonceSignature.base64EncodedString())", to: &Log.log)
        
        popup(on: controller, "certificates：\(certificates)\n\nNonce:\(nonce)\n\nNonceSignature:\(nonceSignature)") { _ in
            
            print("开始请求", to: &Log.log)
            // get active info
            NetworkManager.loadActivationInfo(card: self.currentCard, certificate: certificates.first!, nonce: nonce, nonceSignature: nonceSignature) { (result: VLCardActivationInfo?, success: Bool) in
                let requst = PKAddPaymentPassRequest()
                if let info = result {
                    print("进来了：\(info)", to: &Log.log)
                    requst.activationData = Data(base64Encoded: info.activationData ?? "") //info.activationData?.data(using: .utf8)
                    requst.encryptedPassData = Data(base64Encoded: info.encryptedPassData ?? "")
                    requst.ephemeralPublicKey = Data(base64Encoded: info.ephemeralPublicKey ?? "")
                }
                print("返回request", to: &Log.log)
                handler(requst)
            }
        }
    }
    
    func popup(on vc: UIViewController,_ message: String, completion: ((UIAlertAction) -> Void)? = nil) {
        let popup = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        popup.addAction(.init(title: "got it", style: .default, handler: completion))
        vc.present(popup, animated: true, completion: nil)
    }
    
    func addPaymentPassViewController(_ controller: PKAddPaymentPassViewController, didFinishAdding pass: PKPaymentPass?, error: Error?) {
        if error == nil && pass != nil {
            print("Success")
        }
        controller.dismiss(animated: true, completion: nil)
        popup(on: self, "pass:\(pass?.activationState == nil ? "nil": String(pass?.activationState.rawValue ?? 999) )\nerror:\(error?.localizedDescription ?? "nil")")
    }
}


extension String {
    var last4Characters: String {
        return self.count > 3 ? String(self.suffix(4)) : self
    }
}


class Log: TextOutputStream {

    func write(_ string: String) {
        let fm = FileManager.default
        let log = fm.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("log.txt")
        if let handle = try? FileHandle(forWritingTo: log) {
            handle.seekToEndOfFile()
            handle.write(string.data(using: .utf8)!)
            handle.closeFile()
        } else {
            try? string.data(using: .utf8)?.write(to: log)
        }
    }
    static var log: Log = Log()
    private init() {} // we are sure, nobody else could create it
}
