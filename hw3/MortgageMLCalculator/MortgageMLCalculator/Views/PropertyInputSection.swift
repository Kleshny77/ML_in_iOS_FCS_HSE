import SwiftUI

struct PropertyInputSection: View {
    
    @ObservedObject var viewModel: MortgageViewModel
    
    var body: some View {
        Section {
            ParameterRow(
                title: "Площадь",
                value: $viewModel.areaText,
                unit: "м²"
            )
            
            ParameterRow(
                title: "Комнаты",
                value: $viewModel.roomsText,
                unit: "шт.",
                keyboardType: .numberPad
            )
            
            ParameterRow(
                title: "Санузлы",
                value: $viewModel.bathroomsText,
                unit: "шт.",
                keyboardType: .numberPad
            )
            
            ParameterRow(
                title: "Парковочные места",
                value: $viewModel.garageText,
                unit: "шт.",
                keyboardType: .numberPad
            )
            
            ParameterRow(
                title: "До центра",
                value: $viewModel.distanceText,
                unit: "км"
            )
            
            ParameterRow(
                title: "Этаж",
                value: $viewModel.floorText,
                unit: "эт.",
                keyboardType: .numberPad
            )
            
            ParameterRow(
                title: "Год постройки",
                value: $viewModel.buildYearText,
                unit: "год",
                keyboardType: .numberPad
            )
        } header: {
            Text("Характеристики недвижимости")
        }
    }
}

#Preview {
    List {
        PropertyInputSection(viewModel: MortgageViewModel())
    }
}
