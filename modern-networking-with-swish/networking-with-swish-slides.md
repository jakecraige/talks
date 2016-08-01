# Modern Networking with Swish
### by Jake Craige

---

![100%](assets/thoughtbot-logo.png)

---

![left 75%](assets/swish-logo.png)

# [fit] Swish
## [fit] Nothing but net(working)

---

![right 40%](assets/argo-logo.png)

# [fit] Argo
## [fit] Functional JSON parsing library

---

# Setting up a Model with Argo

```swift
struct Comment {
  let id: Int
  let text: String
  let username: String
}

extension Comment: Decodable {
  static func decode(json: JSON) -> Decoded<Comment> {
    return curry(Comment.init)
      <^> json <| "id"
      <*> json <| "commentText"
      <*> json <| "username"
  }
}
```

---

# Building a Swish Request

```swift
struct CommentRequest: Request {
  typealias ResponseObject = Comment

  let id: Int

  func build() -> NSURLRequest {
    let url = NSURL(string: "https://www.example.com/comments/\(id)")!
    return NSURLRequest(URL: url)
  }
}
```

---

# Executing the Swish Request

```swift
let request = CommentRequest(id: 1)

APIClient().performRequest(request) { (result: Result<Comment, SwishError>) in
  switch result {
  case let .Success(comment):
    print("Here's the comment: \(value)")
  case let .Failure(error):
    print("Oh no, an error: \(error)")
  }
}
```

---

# Let's break it down

---

# Argo's `Decodable`

```swift
protocol Decodable {
  associatedtype DecodedType = Self
  static func decode(_ json: JSON) -> Decoded<DecodedType>
}
```

---

# Swish's `Request`

```swift
protocol Parser {
  associatedtype Representation

  static func parse(j: AnyObject) -> Result<Representation, SwishError>
}

protocol Request {
  associatedtype ResponseObject
  associatedtype ResponseParser: Parser = JSON

  func build() -> NSURLRequest
  func parse(j: ResponseParser.Representation) -> Result<ResponseObject, SwishError>
}
```

---


