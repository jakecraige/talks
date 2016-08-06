build-lists: true

# Modern Networking with Swish
### @jakecraige

^ Tell story about what we're going to do, request and create comments, and test
  them

---

![100%](assets/thoughtbot-logo.png)

---

![right 40%](assets/argo-logo.png)

# [fit] Argo
## [fit] Functional JSON parsing library

---

![left 75%](assets/swish-logo.png)

# [fit] Swish
## [fit] Nothing but net(working)

^ Provides an API around `NSURLRequest`

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

^ Gloss over Argo syntax, assume when given JSON, this will return a `Comment`
^ TOOD: reference Argo article?

---

# Building a GET Request

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

# Executing the GET Request

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

// => Comment(id: 1, text: "I want to learn about Swish.", username: "ralph")
```

---

## GETs are easy.
## How about POSTs?

---

# Building a POST Request

```swift
struct CreateCommentRequest: Request {
  typealias ResponseObject = Comment

  let text: String
  let username: String

  var jsonPayload: [String: AnyObject] {
    return [
      "text": text,
      "username": username
    ]
  }

  func build() -> NSURLRequest {
    let url = NSURL(string: "https://www.example.com/comments")!
    let request = NSMutableURLRequest(URL: url)
    request.jsonPayload = jsonPayload
    return request
  }
}
```

---

# Executing the POST Request

```swift
let request = CreateCommentRequest(text: "I'm learning!", username: "ralph")

APIClient().performRequest(request) { (result: Result<Comment, SwishError>) in
  switch result {
  case let .Success(comment):
    print("Here's the comment: \(value)")
  case let .Failure(error):
    print("Oh no, an error: \(error)")
  }
}

// => Comment(id: 2, text: "I'm learning!", username: "ralph")
```

---

# 🤔
## Still easy.

---

# Comparison

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

# Comparison

```swift
let request = CreateCommentRequest(text: "I'm learning!", username: "ralph")

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

## Let's break it down 💃

---

# Argo's `Decodable`

```swift
protocol Decodable {
  associatedtype DecodedType = Self
  static func decode(_ json: JSON) -> Decoded<DecodedType>
}
```

^ TODO: Is associated type inference being removed?
^ TODO: Why the `Self` thing?

---

# Argo's `Decodable`

```swift
protocol Decodable {
  associatedtype DecodedType = Self
  static func decode(_ json: JSON) -> Decoded<DecodedType>
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

^ TODO: Is associated type inference being removed?

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
  func parse(j: ResponseParser.Representation) 
                -> Result<ResponseObject, SwishError>
}
```

^ TODO: Does Swish comes with other parsers?
^ Swish extends Argo's JSON type for default `Parser`

---

# Swish's `Request`

```swift
protocol Request {
  associatedtype ResponseObject
  associatedtype ResponseParser: Parser = JSON

  func build() -> NSURLRequest
  func parse(j: ResponseParser.Representation) -> Result<ResponseObject, SwishError>
}

struct CommentRequest: Request {
  typealias ResponseObject = Comment

  let id: Int

  func build() -> NSURLRequest {
    let url = NSURL(string: "https://www.example.com/comments/\(id)")!
    return NSURLRequest(URL: url)
  }
}
```

^ Notice no `parse` implementation

---

# Testing

^ TODO: Helpers defined in a gist.
  We use Quick and Nimble.
  Because we're able to build up a request without executing it, it's easy to
  build it in test and make assertions against it.

---

# Testing Retrieving a Comment

```swift
itBehavesLike(.GETRequest, request: CommentRequest(id: 1))

it("points to /comments/:id") {
  let request = CommentRequest(id: 1)

  expect(request.build()).to(hitEndpoint("/comments/1"))
}
```

---

# Testing Creating a Comment

```swift
itBehavesLike(.POSTRequest, request: CreateCommentRequest(text: "", username: ""))

it("points to /comments") {
  let request = CreateCommentRequest(text: "", username: "")

  expect(request.build()).to(hitEndpoint("/comments"))
}

it("has a payload with the text and username") {
  let request = CreateCommentRequest(text: "Hi!", username: "ralph")

  expect(request.build()).to(havePayload([
    "text": "Hi!",
    "username": "ralph"
  ]))
}
```

---

# What else can you do with Swish?

---

# What else can you do with Swish?

1. Cancel in-flight requests
1. Execute requests on different queues.
1. Support arbitrary JSON parsers or response types.
1. Anything you want. 

^ Swish is implemented with exclusively value types and protocols which makes it
  _completely_ pluggable.

---

# Thanks. Questions?

- [https://tbot.io/swish-talk]()
- @jakecraige

