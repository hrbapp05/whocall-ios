import type { Metadata } from "next";
import { LegalPage, type LegalSection } from "../components/LegalPage";

export const metadata: Metadata = {
  title: "Terms of Use",
  description: "Terms governing WhoCall accounts, lookups, community features, credits, and subscriptions.",
  alternates: { canonical: "/terms-of-use" },
};

const sections: LegalSection[] = [
  {
    id: "acceptance",
    title: "Acceptance",
    content: <p>By downloading, opening, or using the WhoCall app or website, you agree to these Terms of Use and our Privacy Policy. If you do not agree, do not use WhoCall. The service is provided by BLAVI LLC for users in Türkiye.</p>,
  },
  {
    id: "service",
    title: "The WhoCall service",
    content: <>
      <p>WhoCall may provide a shortened name associated with a Turkish mobile number, together with community labels, comments, reports, and a trust indicator. Results may be based on database records, verified user profiles, and community contributions.</p>
      <div className="legal-callout"><p>WhoCall is not an identity-verification, emergency, financial-assessment, or law-enforcement service. We do not guarantee that a result will exist or that every result will be complete, current, or error-free.</p></div>
    </>,
  },
  {
    id: "account",
    title: "Accounts and phone verification",
    content: <>
      <p>You may use only your own phone number, or a number you are authorized to control, when creating an account. Keep SMS verification codes confidential and take reasonable steps to protect your account.</p>
      <p>You may not create a profile with false or misleading details, impersonate another person, bypass verification, automate account creation, or defeat security controls.</p>
    </>,
  },
  {
    id: "acceptable-use",
    title: "Acceptable use",
    content: <>
      <p>You may use WhoCall only for personal and lawful purposes. You must not:</p>
      <ul>
        <li>Use WhoCall for harassment, stalking, threats, discrimination, doxing, or invasion of privacy.</li>
        <li>Scrape, copy, aggregate, resell, or use results to build a large-scale phone directory.</li>
        <li>Access the app or API without authorization or bypass rate limits, payment controls, or security measures.</li>
        <li>Submit malware, spam, advertising, profanity, abusive statements, deceptive reports, or unlawful content.</li>
        <li>Infringe the intellectual-property or other rights of WhoCall or any third party.</li>
      </ul>
    </>,
  },
  {
    id: "community",
    title: "Community content",
    content: <>
      <p>When you submit a comment, label, or report, you represent that you reasonably believe it is accurate, that you have the right to submit it, and that it does not unlawfully disclose personal data.</p>
      <p>You retain ownership of your content. You grant BLAVI LLC a worldwide, non-exclusive, royalty-free license to host, reproduce, format, display, moderate, and use that content as necessary to operate, secure, and improve WhoCall. We may remove content or restrict accounts that violate these Terms.</p>
    </>,
  },
  {
    id: "purchases",
    title: "Credits, Premium, and billing",
    content: <>
      <h3>Lookup credits</h3>
      <p>Credits provide the number of paid lookup results shown at purchase. Credits have no cash value, are not transferable, and are not refundable except where required by law or Apple policy.</p>
      <h3>Premium subscriptions</h3>
      <p>Premium may provide unlimited lookups and other features for the selected period. Subscriptions automatically renew through your Apple Account unless cancelled at least 24 hours before the current period ends. Price and billing period are displayed before purchase confirmation.</p>
      <h3>Management and refunds</h3>
      <p>You can manage or cancel a subscription in your Apple Account subscription settings. Apple processes payments and handles refund requests under its applicable policies. WhoCall may provide a restore-purchases control in the app.</p>
    </>,
  },
  {
    id: "license",
    title: "App license and Apple terms",
    content: <>
      <p>BLAVI LLC grants you a limited, personal, revocable, non-exclusive, non-transferable license to use WhoCall on Apple-branded devices you own or control, subject to the App Store Usage Rules and these Terms. You may not copy, modify, reverse engineer, redistribute, sublicense, or commercially exploit the app except where applicable law does not allow that restriction.</p>
      <p>These Terms are between you and BLAVI LLC, not Apple. BLAVI LLC, not Apple, is responsible for WhoCall, support, maintenance, product claims, and intellectual-property claims. Apple and its subsidiaries are third-party beneficiaries and may enforce the applicable app-license terms after your acceptance.</p>
      <p>Where these Terms do not address an app-license matter, Apple’s <a href="https://www.apple.com/legal/internet-services/itunes/dev/stdeula/" rel="noreferrer" target="_blank">Standard Licensed Application End User License Agreement</a> applies. If there is a conflict, mandatory App Store terms and applicable law control.</p>
    </>,
  },
  {
    id: "intellectual-property",
    title: "Intellectual property",
    content: <p>The WhoCall name, app icon, interface, software, copy, and other materials created by BLAVI LLC are protected by applicable intellectual-property laws. No rights are granted except the limited right to use the service under these Terms.</p>,
  },
  {
    id: "disclaimers",
    title: "Disclaimers and liability",
    content: <>
      <p>To the fullest extent allowed by law, WhoCall is provided “as is” and “as available.” We disclaim implied warranties of accuracy, fitness for a particular purpose, and uninterrupted availability. Do not rely on a lookup result as the sole basis for an important decision.</p>
      <p>Except for liability that cannot legally be excluded, BLAVI LLC is not liable for indirect, incidental, special, or consequential losses, loss of data or profit, service interruption, or harm caused by user or third-party content. Our aggregate liability will not exceed the amount you paid for WhoCall during the 12 months before the event giving rise to the claim.</p>
    </>,
  },
  {
    id: "termination",
    title: "Suspension and termination",
    content: <p>We may restrict or terminate access if you violate these Terms or applicable law, threaten the security of the service, or harm other users. You may stop using WhoCall at any time. Provisions that by their nature should survive termination will remain effective.</p>,
  },
  {
    id: "law",
    title: "Governing law, changes, and contact",
    content: <>
      <p>These Terms are governed by the laws of Türkiye, without limiting mandatory consumer rights or jurisdiction rules that apply to you. We may update these Terms as WhoCall or applicable rules change. Material changes will be announced through an appropriate channel.</p>
      <p>Questions about these Terms can be sent to <a href="mailto:support@levelappstuido.com">support@levelappstuido.com</a>.</p>
    </>,
  },
];

export default function TermsOfUsePage() {
  return <LegalPage title="Terms of Use" intro="These Terms govern your WhoCall account, lookups, community contributions, credits, subscriptions, and app license." sections={sections} />;
}
