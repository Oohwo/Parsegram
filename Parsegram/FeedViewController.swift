//
//  FeedViewController.swift
//  Parsegram
//
//  Created by Rachel Sacdalan on 2/20/22.
//

import UIKit
import Parse
import AlamofireImage
import MessageInputBar

class FeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MessageInputBarDelegate {
    
    let commentBar = MessageInputBar()
    var showsCommentBar = false
    
    var posts = [PFObject]()
    var selectedPost : PFObject!
    
    var refreshControl : UIRefreshControl!
    
    @IBOutlet weak var postsTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        commentBar.inputTextView.placeholder = "Add a comment..."
        commentBar.sendButton.title = "Post"
        commentBar.delegate = self
        
        postsTableView.delegate = self
        postsTableView.dataSource = self
        
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(onRefresh), for: .valueChanged)
        postsTableView.insertSubview(refreshControl, at: 0)
        
        postsTableView.keyboardDismissMode = .interactive
        
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(keyboardWillBeHidden(note:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillBeHidden(note: Notification) {
        commentBar.inputTextView.text = nil
        showsCommentBar = false
        becomeFirstResponder()
    }
    
    override var inputAccessoryView: UIView? {
        return commentBar
    }
    
    override var canBecomeFirstResponder: Bool {
        return showsCommentBar
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let post = posts[section]
        let comments = (post["comments"] as? [PFObject]) ?? []
        
        return comments.count + 2
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return posts.count
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let query = PFQuery(className: "posts")
        query.includeKeys(["author", "comments", "comments.author"])
        query.limit = 20
        
        query.findObjectsInBackground { (posts, error) in
            if posts != nil {
                self.posts = posts!
                self.postsTableView.reloadData()
            }
        }
    }
    
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        // Create the comment
        let comment = PFObject(className: "Comments")
        
        comment["text"] = text
        comment["post"] = selectedPost
        comment["author"] = PFUser.current()!

        selectedPost.add(comment, forKey: "comments")

        selectedPost.saveInBackground { (success, error) in
            if success {
                print("Comment saved!")
            } else {
                print("Error saving comment!")
            }
        }
        
        postsTableView.reloadData()
        
        // Clear and dismiss the input bar
        commentBar.inputTextView.text = nil
        showsCommentBar = false
        becomeFirstResponder()
        commentBar.inputTextView.resignFirstResponder()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = postsTableView.dequeueReusableCell(withIdentifier: "PostTableViewCell") as! PostTableViewCell
        
        let post = posts[indexPath.section]
        let comments = (post["comments"] as? [PFObject]) ?? []
        
        if indexPath.row == 0 {
            let user = post["author"] as! PFUser
            cell.usernameLabel.text = user.username
            
            if (user["profile_pic"] != nil) {
                let pfpFile = user["profile_pic"] as! PFFileObject
                let pfpUrlString = pfpFile.url!
                let pfpUrl = URL(string: pfpUrlString)!
                
                cell.profilePicView.af.setImage(withURL: pfpUrl)
            } else {
                let awesome_face = "https://static.wikia.nocookie.net/meme/images/1/16/AwesomeFace-1.png/revision/latest?cb=20200913165007"
                let stockImageUrl = URL(string: awesome_face)!
                cell.profilePicView.af.setImage(withURL: stockImageUrl)
            }
            
            let captionStr : String = post["caption"] as! String
            cell.captionLabel.text = captionStr
            
            let imageFile = post["image"] as! PFFileObject
            let urlString = imageFile.url!
            let url = URL(string: urlString)!
            
            cell.photoView.af.setImage(withURL: url)
            
            return cell
        } else if indexPath.row <= comments.count {
            let cell = postsTableView.dequeueReusableCell(withIdentifier: "CommentTableViewCell") as! CommentTableViewCell
            
            let comment = comments[indexPath.row - 1]
            cell.commentLabel.text = comment["text"] as? String
            
            let user = comment["author"] as! PFUser
            cell.nameLabel.text = user.username
            
            if (user["profile_pic"] != nil) {
                let pfpFile = user["profile_pic"] as! PFFileObject
                let pfpUrlString = pfpFile.url!
                let pfpUrl = URL(string: pfpUrlString)!
                
                cell.profilePicView.af.setImage(withURL: pfpUrl)
            } else {
                let awesome_face = "https://static.wikia.nocookie.net/meme/images/1/16/AwesomeFace-1.png/revision/latest?cb=20200913165007"
                let stockImageUrl = URL(string: awesome_face)!
                cell.profilePicView.af.setImage(withURL: stockImageUrl)
            }
            
            return cell
        } else {
            let cell = postsTableView.dequeueReusableCell(withIdentifier: "AddCommentCell")
            
            return cell!
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = posts[indexPath.section]
        let comments = (post["comments"] as? [PFObject]) ?? []
        
        if indexPath.row == comments.count + 1 {
            showsCommentBar = true
            becomeFirstResponder()
            commentBar.inputTextView.becomeFirstResponder()
            
            selectedPost = post
        }
    }
    
    @objc func onRefresh() {
        run(after: 2) {
            self.refreshControl.endRefreshing()
        }
    }
    
    func run(after wait: TimeInterval, closure: @escaping () -> Void) {
        let queue = DispatchQueue.main
        queue.asyncAfter(deadline: DispatchTime.now() + wait, execute: closure)
    }

    @IBAction func onLogoutButton(_ sender: Any) {
        PFUser.logOut()
        
        let main = UIStoryboard(name: "Main", bundle: nil)
        let loginViewController = main.instantiateViewController(withIdentifier: "LoginViewController")
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, let delegate = windowScene.delegate as? SceneDelegate else {return}
        
        delegate.window?.rootViewController = loginViewController
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
