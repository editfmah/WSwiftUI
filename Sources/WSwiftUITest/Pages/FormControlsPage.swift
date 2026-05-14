import Foundation
import WSwiftUI

class FormControlsPage: CoreWebEndpoint, WebEndpoint, WebContent, MenuIndexable {
    var authenticationRequired: [WebAuthenticationStatus] = [.unauthenticated]

    var menuPrimary: String = "Controls"

    var menuSecondary: String? = "Forms & Inputs"

    override func content() -> Any? {
        let fullName = WString("").name("full_name")
        let email = WString("").name("email")
        let password = WString("").name("password")
        let about = WString("").name("about")
        let termsAccepted = WBool(false).name("terms_accepted")
        let plan = WString("starter").name("plan")
        let contact = WString("email").name("contact")
        let country = WString("gb").name("country")

        return DemoPage(
            title: "Form & Input Controls",
            subtitle: "Demonstrations for form composition, binding, validation, and uploads."
        ) {
            if let submittedName = ephemeralData["submitted_name"] as? String {
                Alert(.success, dismissible: true) {
                    Text("Saved form for \(submittedName).")
                }.margin(.bottom, 16)
            }

            DemoSection(
                "Form + TextField + SecureField + TextArea",
                description: "Input controls bind directly to reactive variables and support validation.",
                code: """
Form(action: self.path, method: .post) {
    TextField("Full name", text: fullName).validate([.notEmpty, .atLeast(2)])
    TextField("Email", text: email, type: .email).validate([.notEmpty, .validEmail])
    SecureField("Password", text: password).validate([.notEmpty, .atLeast(8)])
    TextArea("About", text: about)
    Button("Submit", type: "submit").variant(.primary)
}
"""
            ) {
                Form(action: self.path, method: .post, encType: .multipart) {
                    TextField("Full name", text: fullName, prompt: "Jane Doe")
                        .validate([.notEmpty, .atLeast(2)])

                    TextField("Email", text: email, type: .email, prompt: "jane@example.com")
                        .validate([.notEmpty, .validEmail])

                    SecureField("Password", text: password, prompt: "8+ characters")
                        .validate([.notEmpty, .atLeast(8)])

                    TextArea("About", text: about, prompt: "Tell us a little about yourself")
                        .rows(4)

                    Toggle("Accept terms and privacy policy", isOn: termsAccepted)
                        .margin(.top, 8)

                    Text("Country").font(.subtitle).bold().padding([.top, .bottom], 8)
                    Picker("Country", selection: country, style: .menu) {
                        Text("United Kingdom").value("gb")
                        Text("United States").value("us")
                        Text("Germany").value("de")
                    }

                    Text("Plan").font(.subtitle).bold().padding([.top, .bottom], 8)
                    Picker("Plan", selection: plan, style: .segmented(.primary)) {
                        Text("Starter").value("starter")
                        Text("Pro").value("pro")
                        Text("Enterprise").value("enterprise")
                    }

                    Text("Preferred contact").font(.subtitle).bold().padding([.top, .bottom], 8)
                    Picker("Preferred contact", selection: contact, style: .radio(.horizontal)) {
                        Text("Email").value("email")
                        Text("Phone").value("phone")
                        Text("SMS").value("sms")
                    }

                    Button("Submit form", type: "submit")
                        .variant(.primary)
                        .margin(.top, 16)
                }
            }

            DemoSection(
                "FileUploader",
                description: "Drag-and-drop and click-to-upload helper with post-upload action hooks.",
                code: """
FileUploader(action: "/api/controls", onUpload: [.alert("Upload finished")]) {
    Text("Drop files here")
}
"""
            ) {
                FileUploader(action: "/api/controls", onUpload: [
                    .alert("Upload finished")
                ]) {
                    Text("Drop files here or click to choose")
                        .font(.title2)
                        .foreground(.darkgrey)
                }
            }
            
            InteractiveBindingActionsSection(pageKey: "forms")
        }
    }

    override func persist() -> Any? {
        let valid = validateData([
            .named("full_name", [.notEmpty, .atLeast(2)]),
            .named("email", [.notEmpty, .validEmail]),
            .named("password", [.notEmpty, .atLeast(8)])
        ])
        if !valid {
            return content()
        }

        ephemeralData["submitted_name"] = data.string("full_name") ?? "Unknown"
        return content()
    }

    var controller: String? = "controls"

    var method: String? = "forms"

    func acceptedRoles(for action: WebRequestActivity) -> [String]? {
        return nil
    }
}
