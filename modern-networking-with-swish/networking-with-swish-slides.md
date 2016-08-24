build-lists: true

# Modern Networking with Swish
### @jakecraige

^ Better titled, "Networking with Swish", but that didn't sound as cool.
  Why? Huge WebService class, DRY, testability, composability
  What? We're going create a request to retrieve comments, create them, and test
  them.

---

![100%](assets/thoughtbot-logo.png)

^ consulting company of designers and developers who'll partner with you to create
  great products for web and mobile.

---

![right 40%](assets/argo-logo.png)

# [fit] Argo
## [fit] Functional JSON parsing library

^ Not Swish requirement, but recommended.

---

![left 75%](assets/swish-logo.png)

# [fit] Swish
## [fit] Nothing but net(working)

^ Provides an API around `NSURLRequest` to build requests. Entirely value type
  and protocol based.

---

# Setting up a Model with Argo

```swift
struct Comment {
  let id: Int
  let text: String
  let user: String
}

extension Comment: Decodable {
  // Assume: { "id": 1, "commentText": "Hello world", "user": "ralph" }
  static func decode(json: JSON) -> Decoded<Comment> {
    return curry(Comment.init)
      <^> json <| "id"
      <*> json <| "commentText"
      <*> json <| "user"
  }
}
```

^ Gloss over Argo syntax, assume when given JSON, this will return a `Comment`

---

# Building a GET Request

```swift
struct CommentRequest: Request {
  typealias ResponseObject = Comment

  let id: Int

  func build() -> NSURLRequest {
    let url = NSURL(
      string: "https://www.example.com/comments/\(id)"
    )!
    return NSURLRequest(URL: url)
  }
}
```

---

# Executing the GET Request

```swift
let request = CommentRequest(id: 1)

APIClient().performRequest(request) { result in
  switch result { // Result<Comment, SwishError>
  case let .Success(comment):
    print("Here's the comment: \(comment)")
  case let .Failure(error):
    print("Oh no, an error: \(error)")
  }
}

// => Comment(id: 1, text: "Hi", user: "ralph")
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
  let user: String

  var jsonPayload: [String: AnyObject] {
    return ["text": text, "user": user]
  }

  func build() -> NSURLRequest {
    // ...
  }
}
```

---

# Building a POST Request

```swift
struct CreateCommentRequest: Request {
  // ...
  func build() -> NSURLRequest {
    let url = NSURL(string: "https://www.example.com/comments")!
    let request = NSMutableURLRequest(URL: url)
    request.HTTPMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.jsonPayload = jsonPayload
    return request
  }
}
```

---

# Executing the POST Request

```swift
let request = CreateCommentRequest(text: "Hola", user: "ralph")

APIClient().performRequest(request) { result in
  switch result { // Result<Comment, SwishError>
  case let .Success(comment):
    print("Here's the comment: \(value)")
  case let .Failure(error):
    print("Oh no, an error: \(error)")
  }
}

// => Comment(id: 2, text: "Hola", user: "ralph")
```

---

# :cool: 😎 

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

^ `Self` because when using `Self`, subclasses don't know what to return. More
  discussion in a thread linked in resources.

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
      <*> json <| "user"
  }
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
  func parse(j: ResponseParser.Representation) 
                -> Result<ResponseObject, SwishError>
}
```

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

^ Helpers defined in a gist linked in resources.
  We use Quick, Nimble, and Nocilla.
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
itBehavesLike(.POSTRequest, request: CreateCommentRequest(text: "", user: ""))

it("points to /comments") {
  let request = CreateCommentRequest(text: "", user: "")

  expect(request.build()).to(hitEndpoint("/comments"))
}

it("has a payload with the text and user") {
  let request = CreateCommentRequest(text: "Hi!", user: "ralph")

  expect(request.build()).to(havePayload([
    "text": "Hi!",
    "user": "ralph"
  ]))
}
```

---

# Stubbing the Network

```swift
it("completes the full request cycle") {
  let request = CommentRequest(id: 1)
  stub(request).with(.comment)

  var response: Comment? = .None
  APIClient().performRequest(request) { response = $0.value }

  expect(response)
    .toEventually(equal(Comment(id: 1, text: "Hallo", user: "ralph")))
}
```

---

# What else can you do with Swish?

^ double-tap next to get to first bullet point

---

# What else can you do with Swish?

1. Dependency injection of `APIClient`, protocol `Client`, for testing
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

