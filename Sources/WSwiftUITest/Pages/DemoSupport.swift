import Foundation
import WSwiftUI

public extension CoreWebEndpoint {
    @discardableResult
    func DemoPage(title: String,
                  subtitle: String? = nil,
                  _ content: WebComposerClosure) -> WebElement {
        Template {
            VStack {
                Text(title).font(.largeTitle).bold().padding(.bottom, 8)
                if let subtitle {
                    Text(subtitle).padding(.bottom, 24)
                }
                content()
            }.padding(40)
        }
    }

    @discardableResult
    func DemoSection(_ title: String,
                     description: String? = nil,
                     code: String? = nil,
                     _ preview: WebComposerClosure) -> WebElement {
        Card {
            CardHeader {
                Text(title).font(.title2).bold()
            }
            CardBody {
                if let description {
                    Text(description).padding(.bottom, 12)
                }
                preview()
                if let code {
                    Text("Usage").font(.subtitle).bold().padding([.top, .bottom], 8)
                    Code(language: .swift, code)
                }
            }
        }.shadow().margin(.bottom, 24)
    }
}
