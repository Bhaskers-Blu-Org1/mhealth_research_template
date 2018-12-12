// Copyright © 2018 IBM.

import Foundation
import ResearchKit
public let consentDocument = ConsentDocument
public var ConsentTask: ORKOrderedTask {

    var steps = [ORKStep]()
    let visualConsentStep = ORKVisualConsentStep(identifier: "VisualConsentStep", document: consentDocument)
    steps += [visualConsentStep]
    let signature = consentDocument.signatures!.first as ORKConsentSignature?
    let reviewConsentStep = ORKConsentReviewStep(identifier: "ConsentReviewStep", signature: signature, in: consentDocument)
    
    reviewConsentStep.title = "Name and signature required."
    reviewConsentStep.text = "Please enter your name here, then sign on the next screen."
    reviewConsentStep.reasonForConsent = "Lorem ipsum..."
    steps += [reviewConsentStep]

    return ORKOrderedTask(identifier: "ConsentTask", steps: steps)
}
