//
//  ArticleViewController.swift
//  Instagram
//
//  Created by 田中翔悟 on 2021/01/15.
//  Copyright © 2021 shogo.tanaka. All rights reserved.
//

import UIKit
import Firebase
import FirebaseUI
import SVProgressHUD

class ArticleViewController: UIViewController {
    
    @IBOutlet weak var articleImageView: UIImageView!
    
    @IBOutlet weak var articleLikeButton: UIButton!
    
    @IBOutlet weak var articleLikeLabel: UILabel!
    
    @IBOutlet weak var articleDateLabel: UILabel!
    
    @IBOutlet weak var articleCaptionLabel: UILabel!
    
    @IBOutlet weak var commentTextField: UITextField!
    
    @IBOutlet weak var commentButton: UIButton!
    
    
    // 前の画面から postData 受け取り用の変数
    var postDataReceived: PostData!
    
    // 投稿データを格納する配列
    var postArray: [PostData] = []

    // Firestoreのリスナー
    var listener: ListenerRegistration!
    
    
    // いいねボタン押した時
    @IBAction func articleLikeButton(_ sender: Any, forEvent event: UIEvent) {
        print("DEBUG_PRINT: likeボタンがタップされました。")
        
        /* if Auth.auth().currentUser != nil {
            // ログイン済み
            if listener == nil {
                // listener未登録なら、登録してスナップショットを受信する
                let postsRef = Firestore.firestore().collection(Const.PostPath).order(by: "date", descending: true)
                listener = postsRef.addSnapshotListener() { (querySnapshot, error) in
                    if let error = error {
                        print("DEBUG_PRINT: snapshotの取得が失敗しました。 \(error)")
                        return
                    }
                    // 取得したdocumentをもとにPostDataを作成し、postArrayの配列にする。
                    self.postArray = querySnapshot!.documents.map { document in
                        print("DEBUG_PRINT: document取得 \(document.documentID)")
                        let postData = PostData(document: document)
                        return postData
                    }
                    // 表示を更新する
                    self.viewDidLoad()
                }
            }
        } else {
            // ログイン未(またはログアウト済み)
            if listener != nil {
                // listener登録済みなら削除してpostArrayをクリアする
                listener.remove()
                listener = nil
                postArray = []
                self.viewDidLoad()
            }
        } */
        // likesを更新する
        if let myid = Auth.auth().currentUser?.uid {
            // 更新データを作成する
            var updateValue: FieldValue
            if postDataReceived.isLiked {
                // すでにいいねをしている場合は、いいね解除のためmyidを取り除く更新データを作成
                updateValue = FieldValue.arrayRemove([myid])
                postDataReceived.isLiked = false
                let buttonImage = UIImage(named: "like_none")
                self.articleLikeButton.setImage(buttonImage, for: .normal)
//                postDataReceived.likes.count
                let likeNumber = postDataReceived.likes.count-1
                self.articleLikeLabel.text = "\(likeNumber)"
            } else {
                // 今回新たにいいねを押した場合は、myidを追加する更新データを作成
                updateValue = FieldValue.arrayUnion([myid])
                postDataReceived.isLiked = true
                let buttonImage = UIImage(named: "like_exist")
                self.articleLikeButton.setImage(buttonImage, for: .normal)
                let likeNumber = postDataReceived.likes.count
                self.articleLikeLabel.text = "\(likeNumber)"
            }
            // likesに更新データを書き込む
            let postRef = Firestore.firestore().collection(Const.PostPath).document(postDataReceived.id)
            postRef.updateData(["likes": updateValue])
        }
        // いいねボタンの表示
       
        
    }
    
    
    // コメント投稿ボタン押した時
    @IBAction func commentButton(_ sender: Any) {
        
        if let comment = commentTextField.text {
            if comment.isEmpty {
            SVProgressHUD.showError(withStatus: "コメントを入力して下さい")
            return
        }
    }
        // コメントの保存場所を定義する
//        let commentRef = Firestore.firestore().collection(Const.PostPath).document(postDataReceived.id)
        
        // HUDで投稿処理中の表示を開始
        SVProgressHUD.show()

        // FireStoreに名前とコメントを保存する
//        let name = Auth.auth().currentUser?.displayName
        
//        let commentDic = [
//                 "name": name!,
//                 "comment": self.commentTextField.text!
//            ] as [String : Any]
//        commentRef.updateData([
//            "comment" : commentTextField.text!,
//            "name" : name!
//        ])
//        commentRef.updateData(commentDic)
        
        
        //　コメントとログイン中のユーザー名を保存
        let username_comment = Auth.auth().currentUser!.displayName! + ":" + self.commentTextField.text!
            var updateValue: FieldValue
            updateValue = FieldValue.arrayUnion([username_comment])
            // comment に更新データを書き込む
            let postRef = Firestore.firestore().collection(Const.PostPath).document(postDataReceived.id)
            postRef.updateData(["comment": updateValue])
        
        // コメントを投稿した人の名前を保存
//        if let commentUserName = Auth.auth().currentUser?.displayName {
//            var updateValue: FieldValue
//            updateValue = FieldValue.arrayUnion([commentUserName])
//            let postRef = Firestore.firestore().collection(Const.PostPath).document(postDataReceived.id)
//            postRef.updateData(["comment": updateValue])
//        }
        
        
        // 投稿完了を表示
        SVProgressHUD.showSuccess(withStatus: "投稿しました")
        
        // 最初の画面に戻る
        UIApplication.shared.windows.first{ $0.isKeyWindow }?.rootViewController?.dismiss(animated: true, completion: nil)
        
        
        }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let postData = postDataReceived else {
            return
        }
        
        // いいねの数
        let likeNumber = postDataReceived.likes.count
        self.articleLikeLabel.text = "\(likeNumber)"
        
        
        // キャプション
        self.articleCaptionLabel.text = postDataReceived.caption
        
        // 画像の表示
        articleImageView.sd_imageIndicator = SDWebImageActivityIndicator.gray
        let imageRef = Storage.storage().reference().child(Const.ImagePath).child(postData.id + ".jpg")
        articleImageView.sd_setImage(with: imageRef)
        
        // 日時
        self.articleDateLabel.text = ""
        if let date = postDataReceived.date {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            let dateString = formatter.string(from: date)
            self.articleDateLabel.text = dateString
        }
    }
 
    override func viewDidLoad() {
        super.viewDidLoad()

        if postDataReceived.isLiked {
                   let buttonImage = UIImage(named: "like_exist")
                   self.articleLikeButton.setImage(buttonImage, for: .normal)
               } else {
                   let buttonImage = UIImage(named: "like_none")
                   self.articleLikeButton.setImage(buttonImage, for: .normal)
               }
        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
