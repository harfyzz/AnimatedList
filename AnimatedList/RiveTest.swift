//
//  RiveTest.swift
//  AnimatedList
//
//  Created by Afeez Yunus on 13/02/2026.
//

import SwiftUI
import RiveRuntime

struct RiveTest: View {
    @State var disIntegrate = RiveViewModel(fileName: "disintegrate", stateMachineName: "Main")
    @State var isSetUp = false
    @State var effectInstance: RiveDataBindingViewModel.Instance?
    var body: some View {
        VStack{
            disIntegrate.view()
        }.onAppear{
            disIntegrate.setInput("canvasHeight", value: Double(40))
            disIntegrate.setInput("canvasWidth", value: Double(40))
            setupBind()
        }
    }
    private func setupBind() {
        let effectVm = disIntegrate.riveModel?.riveFile.viewModelNamed("mainVm")
        effectInstance = effectVm?.createInstance(fromName: "Instance")
        disIntegrate.riveModel?.stateMachine?.bind(viewModelInstance: effectInstance!)
        effectInstance?.numberProperty(fromPath: "canvasWidth")?.value = Float(180)
        effectInstance?.numberProperty(fromPath: "canvasHeight")?.value = Float(130)
        disIntegrate.triggerInput("advance")
        isSetUp = true
        print("setup complete")
    }
  
}

#Preview {
    RiveTest()
}
