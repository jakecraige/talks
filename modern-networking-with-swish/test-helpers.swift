/// Helpers to make assertions on `Request` objects
import Quick
import Nimble
import Swish

enum APIRequestBehavior: String {
  case BaseRequest = "an API request"
  case GETRequest = "a GET request"
  case POSTRequest = "a POST request"
  case AuthorizedRequest = "an authorized request"
}

func itBehavesLike<T: Request>(behavior: APIRequestBehavior, request: T) {
  itBehavesLike(behavior.rawValue) {
    ["request": request.build()]
  }
}

private func requestFromContext(context: SharedExampleContext) -> NSURLRequest {
  return context()["request"] as! NSURLRequest
}

final class RequestSharedExamplesConfiguration: QuickConfiguration {
  override class func configure(configuration: Configuration) {
    sharedExamples(APIRequestBehavior.GETRequest.rawValue) { (context: SharedExampleContext) in
      itBehavesLike(APIRequestBehavior.BaseRequest.rawValue, sharedExampleContext: context)

      it("is a GET request") {
        let request = requestFromContext(context)

        expect(request.HTTPMethod).to(equal(RequestMethod.GET.rawValue))
      }
    }

    sharedExamples(APIRequestBehavior.BaseRequest.rawValue) { (context: SharedExampleContext) in
      it("points to the correct API") {
        let request = requestFromContext(context)

        // Assumes you have something like this set up in your app to access
        let url = Environment.current.apiBaseURL.absoluteString

        expect(request.URL?.absoluteString).to(beginWith(url))
      }

      it("has an accept type of 'application/json'") {
        let request = requestFromContext(context)

        expect(request.valueForHTTPHeaderField("Accept")).to(equal("application/json"))
      }

      it("has a Content-Type of 'application/json'") {
        let request = requestFromContext(context)

        expect(request.valueForHTTPHeaderField("Content-Type")).to(equal("application/json"))
      }
    }

    sharedExamples(APIRequestBehavior.POSTRequest.rawValue) { (context: SharedExampleContext) in
      it("is a POST request") {
        let request = requestFromContext(context)

        expect(request.HTTPMethod).to(equal(RequestMethod.POST.rawValue))
      }
    }

    sharedExamples(APIRequestBehavior.AuthorizedRequest.rawValue) { (context: SharedExampleContext) in
      it("includes the authorization as a query parameter") {
        let request = requestFromContext(context)
        let queryItems = request.URL.flatMap { NSURLComponents(URL: $0, resolvingAgainstBaseURL: false)?.queryItems }
        expect(queryItems?.contains { $0.name == "authToken" }).to(beTrue())
        expect(queryItems?.contains { $0.value?.nonEmpty != nil }).to(beTrue())
      }
    }
  }
}

public func hitEndpoint(expectedValue: String) -> NonNilMatcherFunc<NSURLRequest> {
  return NonNilMatcherFunc { actual, failure in
    guard let url = try actual.evaluate()?.URL else { return false }

    failure.expected = "expected path of \(url)"
    failure.postfixMessage = "end in <\(expectedValue)>"
    failure.actualValue = .None

    let components = NSURLComponents(URL: url, resolvingAgainstBaseURL: false)
    guard let path = components?.path else { return false }

    return path.hasSuffix(expectedValue)
  }
}

public func havePayload(expectedValue: NSDictionary) -> NonNilMatcherFunc<NSURLRequest> {
  return NonNilMatcherFunc { actual, failure in
    let payload = try actual.evaluate()?.jsonPayload as? NSDictionary

    failure.expected = "expected request"
    failure.postfixMessage = "have payload <\(expectedValue)>"
    failure.actualValue = "<\(payload ?? [:])>"

    return payload == expectedValue
  }
}

public func containQueryItems(expectedValue: [NSURLQueryItem]) -> NonNilMatcherFunc<NSURLRequest> {
  return NonNilMatcherFunc { actual, failure in
    guard let url = try actual.evaluate()?.URL else { return false }

    failure.expected = "expected \(url)"
    failure.postfixMessage =
      "have query items <\(expectedValue.map { "\(stringify($0.name)): \(stringify($0.value))" })>"
    failure.actualValue = .None

    let components = NSURLComponents(URL: url, resolvingAgainstBaseURL: false)
    guard let queryItems = components?.queryItems else {
      return false
    }

    return expectedValue.all { queryItems.contains($0) }
  }
}

/// Helpers to stub the network requests
/// Usage: `stub(CommentRequest(id: 2)).with(.comment)`
import Quick
import Nimble
import Swish

enum JSONFixture: String {
  // case for each name of the fixture file
  case comment

  static func load(from fixture: JSONFixture) -> AnyObject? {
    return load(fromFileNamed: fixture.rawValue)
  }

  static func loadData(from fixture: JSONFixture) -> NSData? {
    return loadData(fromFileNamed: fixture.rawValue)
  }

  private static func load(fromFileNamed name: String) -> AnyObject? {
    return loadData(fromFileNamed: name)
      .flatMap { try? NSJSONSerialization.JSONObjectWithData($0, options: []) }
  }

  private static func loadData(fromFileNamed file: String) -> NSData? {
    return NSBundle(forClass: JSONFixture.BundleClass.self)
      .pathForResource(file, ofType: "json")
      .flatMap { NSData(contentsOfFile: $0) }
  }

  private final class BundleClass {}
}

func stub<T: Request>(request: T, file: StaticString = #file, line: UInt = #line) -> LSStubRequestDSL! {
  let req = request.build()
  let URL: String

  if let URLString = req.URL?.absoluteString {
    URL = URLString
  } else {
    XCTFail("expected built request (\(T.self)) to have a URL: \(req)", file: file, line: line)
    URL = ""
  }

  return stubRequest(req.HTTPMethod, URL)
    .withHeaders(req.allHTTPHeaderFields)
    .withBody(req.HTTPBody)
}

extension LSStubRequestDSL {
  func with(json: JSONFixture, file: StaticString = #file, line: UInt = #line) -> LSStubResponseDSL {
    let response = self.andReturn(200)

    if let json = JSONFixture.loadData(from: json) {
      return response.withBody(json)
    } else {
      XCTFail("unabled to load data for JSON fixture: \(json)", file: file, line: line)
      return response
    }
  }
}

class NocillaConfiguration: QuickConfiguration {
  override class func configure(configuration: Configuration!) {
    configuration.beforeSuite {
      LSNocilla.sharedInstance().start()
    }

    configuration.afterSuite {
      LSNocilla.sharedInstance().stop()
    }

    configuration.afterEach {
      LSNocilla.sharedInstance().clearStubs()
    }
  }
}
