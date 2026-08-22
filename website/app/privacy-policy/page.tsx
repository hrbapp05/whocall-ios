import type { Metadata } from "next";
import { LegalPage, type LegalSection } from "../components/LegalPage";

export const metadata: Metadata = {
  title: "Privacy Policy",
  description: "How WhoCall collects, uses, shares, and protects information.",
  alternates: { canonical: "/privacy-policy" },
};

const sections: LegalSection[] = [
  {
    id: "scope",
    title: "Scope and controller",
    content: <>
      <p>This Privacy Policy applies to the WhoCall iOS application and WhoCall website provided by BLAVI LLC. WhoCall is a phone-number lookup and community information service currently offered in Türkiye.</p>
      <p>For privacy questions or requests, contact us at <a href="mailto:support@levelappstudio.com">support@levelappstudio.com</a>.</p>
    </>,
  },
  {
    id: "data",
    title: "Information we process",
    content: <>
      <p>Depending on how you use WhoCall, we may process:</p>
      <ul>
        <li>Account and verification data, including your own mobile number, SMS verification status, Firebase user identifier, and the first and last name you choose to provide.</li>
        <li>Lookup data, including the number you search for and the result returned. Recent searches may be stored on your device or linked to your verified account.</li>
        <li>Community contributions, including comments, labels, and reports you submit. Display names may be shortened for privacy.</li>
        <li>Purchase data, including product identifiers, subscription entitlement, renewal or expiry information, and credit transactions. We do not receive or store your payment-card details.</li>
        <li>Technical and security data needed to protect the service, diagnose errors, prevent abuse, and enforce request limits.</li>
      </ul>
      <div className="legal-callout"><p>WhoCall does not request access to your address book and does not collect the contacts stored on your device.</p></div>
    </>,
  },
  {
    id: "use",
    title: "How we use information",
    content: <ul>
      <li>Authenticate your phone number and provide secure account access.</li>
      <li>Return number-lookup results, community labels, comments, reports, and trust indicators.</li>
      <li>Apply the name and search-visibility preferences associated with your verified number.</li>
      <li>Manage Premium subscriptions, lookup credits, and purchase history.</li>
      <li>Prevent spam, fraud, abusive content, and unauthorized or excessive use.</li>
      <li>Maintain, troubleshoot, and improve WhoCall and respond to support or legal requests.</li>
    </ul>,
  },
  {
    id: "basis",
    title: "Legal bases",
    content: <p>We process information as necessary to perform our agreement with you, based on your consent where required, to comply with legal obligations, to establish or protect legal rights, and for legitimate interests such as service security and fraud prevention. For users in Türkiye, we aim to process personal data in accordance with Law No. 6698 on the Protection of Personal Data and other applicable rules.</p>,
  },
  {
    id: "providers",
    title: "Service providers and transfers",
    content: <>
      <p>We share limited information with providers that help us operate WhoCall:</p>
      <ul>
        <li>Google Firebase for phone authentication, server functions, and data infrastructure.</li>
        <li>RevenueCat and Apple for in-app purchases, subscription status, and entitlements.</li>
        <li>WhoCall API and hosting providers for secure lookup processing and service delivery.</li>
        <li>Meta SDK and RevenueCat&apos;s Meta Conversions API integration, only when you authorize Apple&apos;s App Tracking Transparency permission, to measure app activations and verified subscription or purchase outcomes from our advertising campaigns.</li>
      </ul>
      <p>We do not send a searched phone number, lookup result, person name, comment, label, or report to Meta. Meta purchase events are generated from RevenueCat&apos;s verified transaction lifecycle, not from WhoCall lookup data. These providers may process data outside Türkiye under their contractual and legal safeguards. We do not sell personal information to advertising networks.</p>
    </>,
  },
  {
    id: "visibility",
    title: "Search visibility and community content",
    content: <>
      <p>After you verify your own number by SMS and add your name, that profile may take priority over a database result while your search visibility is enabled. WhoCall is designed to show only the initial of a surname in lookup results. You can turn visibility off from your profile.</p>
      <p>Comments and labels may be visible to other verified users. We use moderation tools and reporting controls to restrict profanity, harassment, and unlawful content. Do not post private information that you do not want others to see.</p>
    </>,
  },
  {
    id: "retention",
    title: "Retention and security",
    content: <>
      <p>We retain information only for as long as needed to provide WhoCall, maintain an active account, resolve disputes, prevent abuse, or meet legal requirements. Some data, such as certain recent searches, may remain only on your device.</p>
      <p>We use authentication, access controls, request limits, and pseudonymous identifiers to protect data. No electronic system can guarantee absolute security.</p>
    </>,
  },
  {
    id: "rights",
    title: "Your choices and rights",
    content: <>
      <p>Depending on applicable law, you may request access, correction, deletion, restriction, or objection, and may withdraw consent. You can manage search visibility in the app.</p>
      <p>Advertising measurement is optional. You can decline Apple&apos;s App Tracking Transparency prompt without losing access to WhoCall, and you can change that choice later in iOS Settings.</p>
      <p>To request account or data deletion, email <a href="mailto:support@levelappstudio.com?subject=WhoCall%20Account%20Deletion%20Request">support@levelappstudio.com</a> with the subject “WhoCall Account Deletion Request.” Do not include your full phone number in the email body. We may ask you to verify the request through the app or another secure step.</p>
    </>,
  },
  {
    id: "children",
    title: "Children and changes",
    content: <p>WhoCall is not directed to children under 13. We may update this policy when the service or applicable rules change. Material changes will be announced through the app, this website, or another appropriate channel, and the updated date above will be revised.</p>,
  },
];

export default function PrivacyPolicyPage() {
  return <LegalPage title="Privacy Policy" intro="This policy explains what WhoCall processes, why we process it, and the controls available to you." sections={sections} />;
}
