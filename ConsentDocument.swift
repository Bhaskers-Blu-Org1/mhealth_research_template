// Copyright © 2018 IBM.

import Foundation
import ResearchKit

public var ConsentDocument: ORKConsentDocument {
    let consentDocument = ORKConsentDocument()
    consentDocument.title = NSLocalizedString("Study Consent Form", comment: "")
    consentDocument.signaturePageTitle = "Signature: Consent to participate in Research"
    consentDocument.signaturePageContent = "Consent language here"
    let section1 = ORKConsentSection(type: .overview)
    section1.title = "Description"
    section1.summary =  NSLocalizedString("Description section goes here.", comment: "")
    section1.content = section1.summary
    section1.customLearnMoreButtonTitle = ""
    
    let section2 = ORKConsentSection(type: .dataGathering)
    section2.title = "Methods"
    section2.summary = NSLocalizedString("Methods section goes here.", comment: "")
     section2.content = section2.summary
    
     section2.customLearnMoreButtonTitle = ""
    
    let section3 = ORKConsentSection(type: .studyTasks)
    section3.title = "Benefits & Risks"
    section3.summary =  NSLocalizedString("Benefits section goes here", comment: "")
   
    section3.content = section3.summary
    section3.customLearnMoreButtonTitle = ""
    
    let section4 = ORKConsentSection(type: .privacy)
    section4.title = "Data Confidentiality & Security"
    section4.summary =  NSLocalizedString("Privacy section goes here.", comment: "")
    section4.content =  section4.summary
    section4.customLearnMoreButtonTitle = ""
    
    let section5 = ORKConsentSection(type: .dataUse)
    section5.title = "Sharing of Research Data & Results"
    section5.summary =  NSLocalizedString("Data useage section goes here.", comment: "")
    section5.content =  section5.summary
    section5.customLearnMoreButtonTitle = ""
    
    let section6 = ORKConsentSection(type: .studyTasks)
    section6.title = "Contact Information"
    section6.summary =  NSLocalizedString("Study tasks go here.", comment: "")
  
    section6.content =  section6.summary
    section6.customLearnMoreButtonTitle = ""
    
    let date = Date()
    let formatter = DateFormatter()
    formatter.dateFormat = "MM.dd.yyyy"
    let tempDate = formatter.string(from: date)
    consentDocument.sections = [section1, section2, section3, section4, section5, section6]
    consentDocument.addSignature(ORKConsentSignature(forPersonWithTitle: "sig", dateFormatString: tempDate, identifier: "ConsentDocumentParticipantSignature"))

    return consentDocument
}
