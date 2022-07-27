//
//  LoginViewController.swift
//  FBChatAppPrac
//
//  Created by Reese on 2022/07/08.
//

import UIKit
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import JGProgressHUD

final class LoginViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "logo")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let emailField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Email Address..."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        return field
    }()
    
    private let passwordField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Password..."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        field.isSecureTextEntry = true
        return field
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton()
        button.setTitle("Log In", for: .normal)
        button.backgroundColor = .black
        button.setTitleColor(UIColor.white, for: .normal)
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 12
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    private var googleButton: GIDSignInButton = {
        let button = GIDSignInButton()
        button.style = .wide
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Log In"
        view.backgroundColor = .white
        naviBar()
        
        loginButton.addTarget(self,
                              action: #selector(loginButtonTapped),
                              for: .touchUpInside)
        
        googleButton.addTarget(self,
                               action: #selector(handleGoogleLogin),
                               for: .touchUpInside)
        
        emailField.delegate = self
        passwordField.delegate = self
        
        // Add Subviews
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButton)
        scrollView.addSubview(googleButton)
    }
        
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        
        let size = scrollView.width / 3
        imageView.frame = CGRect(x: (view.width - size) / 2,
                                 y: 30,
                                 width: size,
                                 height: size)
        emailField.frame = CGRect(x: 30,
                                  y: imageView.bottom + 30,
                                  width: scrollView.width - 60,
                                  height: 52)
        passwordField.frame = CGRect(x: 30,
                                     y: emailField.bottom + 10,
                                     width: scrollView.width - 60,
                                     height: 52)
        loginButton.frame = CGRect(x: 30,
                                   y: passwordField.bottom + 10,
                                   width: scrollView.width - 60,
                                   height: 52)
        googleButton.frame = CGRect(x: 30,
                                    y: loginButton.bottom + 10,
                                    width: scrollView.width - 60,
                                    height: 52)
    }
    
    private func naviBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(didTapRegister))
        navigationItem.rightBarButtonItem?.tintColor = .lightGray
    }
    
    @objc private func loginButtonTapped() {
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        guard let email = emailField.text, let password = passwordField.text,
              !email.isEmpty, !password.isEmpty, password.count >= 6 else {
            alertUserLoginError()
            return
        }
        
        //JGProgress
        spinner.show(in: view)
        
        //Firebase Log In
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let strongSelf = self else { return }
            
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
            }
            
            guard let result = authResult, error == nil else {
                print("Failed to log in user with email: \(email)")
                return
            }
            
            let user = result.user
            
            // Saving User Email
            UserDefaults.standard.set(email, forKey: "email")
            
            print("Logged In User: \(user)")
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc private func handleGoogleLogin() {
        //Get Client ID which will be performed after clicking the function
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        
        // Create Google Sign In configuration object.
        let config = GIDConfiguration(clientID: clientID)
        
        // Start the sign in flow
        GIDSignIn.sharedInstance.signIn(with: config, presenting: self) { [weak self] user, error in
            guard let strongSelf = self else { return }
            
            guard error == nil else { return }
            guard let user = user else { return }
            
            if let error = error {
                print("Failed to sign in with Google: \(error)")
                return
            }
            
            print("Did sign in with Google: \(user)")
            
            guard let email = user.profile?.email,
                  let firstName = user.profile?.givenName,
                  let lastName = user.profile?.familyName
            else {
                return
            }
            
            // Saving User Email
            UserDefaults.standard.set(email, forKey: "email")
            
            DatabaseManager.shared.userExists(with: email) { exists in
                if !exists {
                    //insert to database
                    let chatUser = ChatAppUser(fisrtName: firstName,
                                               lastName: lastName,
                                               emailAddress: email)
                    DatabaseManager.shared.insertUser(with: chatUser) { success in
                        if success {
                            //upload image
                            if ((user.profile?.hasImage) != nil) {
                                guard let url = user.profile?.imageURL(withDimension: 200) else { return }
                                
                                URLSession.shared.dataTask(with: url) { data, _, _ in
                                    guard let data = data else { return }
                                    
                                    let fileName = chatUser.profilePictureFileName
                                    StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName) { result in
                                        switch result {
                                        case .success(let downloadUrl):
                                            UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                            print(downloadUrl)
                                        case .failure(let error):
                                            print("Storage Manager Error: \(error)")
                                        }
                                    }
                                }.resume()
                            }
                        }
                    }
                }
            }
            
            // 로그인 후 ID 토큰 가져오기
            user.authentication.do { authentication, error in
                guard error == nil else { return }
                guard let authentication = authentication else { return }
                guard let idToken = authentication.idToken else { return }
                
                let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                               accessToken: authentication.accessToken)
                
                FirebaseAuth.Auth.auth().signIn(with: credential) { authResult, error in
                    guard authResult != nil, error == nil else {
                        print("Failed to login with google credential")
                        return
                    }
                    print("Successfully signed in with Google credential")
                    strongSelf.navigationController?.dismiss(animated: true, completion: nil)
                }
            }
            
        }
    }
    
    func alertUserLoginError() {
        let alert = UIAlertController(title: "Woops",
                                      message: "Please enter all information to log in.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss",
                                      style: .cancel,
                                      handler: nil))
        present(alert, animated: true)
    }
    
    @objc private func didTapRegister() {
        let vc = RegisterViewController()
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)
    }
    
}


extension LoginViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == emailField {
            passwordField.becomeFirstResponder()
        }
        else if textField == passwordField {
            loginButtonTapped()
        }
        
        return true
    }
}
