import SwiftUI
import Charts

struct ContentView: View {
    @State private var age: String = "33"
    @State private var gender: String = "Female"
    @State private var height: String = "150"
    @State private var weight: String = "75"
    @State private var targetWeight: String = "62"
    @State private var targetDate: Date? = nil // Optional target date
    @State private var activityLevel: String = "Lightly active"
    @State private var result: String = ""
    @State private var weightProgress: [(Date, Double)] = []
    
    @State private var weightUnit: String = "kg"
    @State private var heightUnit: String = "cm"
    
    let genderOptions = ["Female", "Male"]
    let activityLevels = ["Sedentary", "Lightly active", "Moderately active", "Very active", "Super active"]
    let weightUnits = ["kg", "lb"]
    let heightUnits = ["cm", "ft/in"]
    
    var body: some View {
        NavigationView {
            Form {
                HStack {
                    Text("Age")
                        .frame(width: 80, alignment: .leading)
                    TextField("Age", text: $age)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .multilineTextAlignment(.trailing)
                }
                
                HStack {
                    Text("Gender")
                        .frame(width: 80, alignment: .leading)
                    Picker("Gender", selection: $gender) {
                        ForEach(genderOptions, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                HStack {
                    Text("Height")
                        .frame(width: 80, alignment: .leading)
                    TextField("Height", text: $height)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Picker("", selection: $heightUnit) {
                        ForEach(heightUnits, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                HStack {
                    Text("Weight")
                        .frame(width: 80, alignment: .leading)
                    TextField("Weight", text: $weight)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .multilineTextAlignment(.trailing)
                    Picker("", selection: $weightUnit) {
                        ForEach(weightUnits, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                HStack {
                    Text("Target Weight")
                        .frame(width: 120, alignment: .leading)
                    TextField("Target Weight", text: $targetWeight)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .multilineTextAlignment(.trailing)
                    Picker("", selection: $weightUnit) {
                        ForEach(weightUnits, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                HStack {
                    Text("Target Date (Optional)")
                        .frame(width: 120, alignment: .leading)
                    DatePicker("Select a date", selection: Binding(
                        get: { targetDate ?? Date() },
                        set: { targetDate = $0 }
                    ), displayedComponents: .date)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.trailing)
                    .background(targetDate == nil ? Color.clear : Color.white)
                
                }

                Picker("Activity Level", selection: $activityLevel) {
                    ForEach(activityLevels, id: \.self) {
                        Text($0)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                Button(action: calculate) {
                    Text("Calculate")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .leading, endPoint: .trailing))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .scaleEffect(1.05)
                        .animation(.easeInOut(duration: 0.2), value: result)
                }
                
                if !result.isEmpty {
                    Text("Result").font(.headline).foregroundColor(.black)
                    Text(result)
                        .padding()
                    if !weightProgress.isEmpty {
                        NavigationLink(destination: ProgressGraphView(weightProgress: weightProgress, initialWeight: Double(weight)!, targetWeight: Double(targetWeight)!, weightUnit: weightUnit)) {
                            Text("View Weekly Progress")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                }
            }
            .navigationTitle("Calorie Calculator")
            .background(Color.white)
            .accentColor(.black)
            .padding()
        }
    }
    
    func calculate() {
        guard let age = Int(age),
              let height = Double(height),
              let weight = Double(weight),
              let targetWeight = Double(targetWeight) else {
            result = "Please enter valid numbers for age, height, weight, and target weight."
            return
        }
        
        // Convert height and weight based on units
        let heightInCm = heightUnit == "ft/in" ? (height * 30.48) : height
        let weightInKg = weightUnit == "lb" ? (weight * 0.453592) : weight
        let targetWeightInKg = weightUnit == "lb" ? (targetWeight * 0.453592) : targetWeight
        
        // Calculate BMR
        let bmr: Double
        if gender == "Female" {
            bmr = 10 * weightInKg + 6.25 * heightInCm - 5 * Double(age) - 161
        } else {
            bmr = 10 * weightInKg + 6.25 * heightInCm - 5 * Double(age) + 5
        }
        
        // Calculate TDEE
        let activityMultiplier: Double
        switch activityLevel {
        case "Sedentary":
            activityMultiplier = 1.2
        case "Lightly active":
            activityMultiplier = 1.375
        case "Moderately active":
            activityMultiplier = 1.55
        case "Very active":
            activityMultiplier = 1.725
        case "Super active":
            activityMultiplier = 1.9
        default:
            activityMultiplier = 1.375
        }
        let tdee = bmr * activityMultiplier
        
        // Calculate calorie deficit and time to reach target weight
        let weightLossPerWeek = 0.45
        let totalWeightLoss = weightInKg - targetWeightInKg
        
        var dailyCaloricIntake = tdee - 500 // Default intake
        let weeksToLoseWeight = totalWeightLoss / weightLossPerWeek
        
        // Adjust for target date if provided
        if let targetDate = targetDate {
            let remainingDays = Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day ?? 0
            let targetWeeklyWeightLoss = totalWeightLoss / Double(remainingDays / 7)
            
            if targetWeeklyWeightLoss > weightLossPerWeek {
                dailyCaloricIntake = tdee - (500 * (targetWeeklyWeightLoss / weightLossPerWeek))
            }
        }
        
        // Calculate weekly progress
        weightProgress = []
        for week in 0..<Int(weeksToLoseWeight) {
            let weeklyDate = Calendar.current.date(byAdding: .weekOfYear, value: week, to: Date())!
            let estimatedWeight = weightInKg - (Double(week) * weightLossPerWeek)
            weightProgress.append((weeklyDate, estimatedWeight))
        }
        
        // Format the result
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        result = """
        Daily Caloric Intake: \(String(format: "%.0f", dailyCaloricIntake)) kcal
        Estimated Date to Reach Target Weight: \((targetDate != nil) ? dateFormatter.string(from: targetDate!): dateFormatter.string(from: Calendar.current.date(byAdding: .weekOfYear, value: Int(weeksToLoseWeight), to: Date())!))
        """
    }
}

struct ProgressGraphView: View {
    let weightProgress: [(Date, Double)]
    let initialWeight: Double
    let targetWeight: Double
    let weightUnit: String
    
    var body: some View {
        VStack {
            Text("Weekly Weight Progress")
                .font(.headline)
                .padding()
            
            ScrollView(.horizontal) {
                Chart {
                    ForEach(weightProgress, id: \.0) { data in
                        BarMark(
                            x: .value("Date", data.0, unit: .day),
                            y: .value("Weight", weightUnit == "lb" ? data.1 * 2.20462 : data.1)
                        )
                        .annotation(position: .top) {
                            Text("\(weightUnit == "kg" ? String(format: "%.1f", data.1) : String(format: "%.1f", data.1 * 2.20462)) \(weightUnit)")
                                .font(.caption)
                        }
                    }
                }
                .chartYScale(domain: [
                    targetWeight,
                    initialWeight
                ])
                .chartXAxis {
                    AxisMarks(values: .stride(by: .weekOfYear)) { value in
                        AxisValueLabel {
                            if let dateValue = value.as(Date.self) {
                                Text("\(dateValue, formatter: customDateFormatter)")
                            }
                        }
                    }
                }
                .frame(width: CGFloat(weightProgress.count) * 60, height: 300)
                .padding()
            }
        }
        .navigationTitle("Progress Graph")
        .padding()
    }
}

private let customDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM dd"
    return formatter
}()

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
