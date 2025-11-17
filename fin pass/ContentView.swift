//
//  ContentView.swift
//  fin pass
//
//  Created by Serena Squitieri on 11/11/25.
//

import SwiftUI
import SwiftData
import LocalAuthentication

//4 swift data
@Model
class Category {
    var title: String
    var icon: String
    
    @Relationship(inverse: \PasswordItem.category)
    var passwords: [PasswordItem] = []
    
    init(title: String, icon: String) {
        self.title = title
        self.icon = icon
    }
}

@Model
class PasswordItem {
    var name: String
    var passwordHash: String
    var category: Category?
    
    init(name: String, passwordHash: String, category: Category?) {
        self.name = name
        self.passwordHash = passwordHash
        self.category = category
    }
}
    

struct ContentView: View {
    
    @State private var isUnlocked = false
    
    var body: some View {
        ZStack{
            if isUnlocked {
                    HomeView()
                      .preferredColorScheme(.dark)
                      .modelContainer(for: [Category.self, PasswordItem.self])
            } else {
                Color.black.ignoresSafeArea()
            }
        }
        .onAppear(perform: authenticate)
    }
    
    func authenticate() {
            let context = LAContext()
            var error: NSError?

            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                
                let reason = "Unlock to see your passwords"

                context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                    
                    DispatchQueue.main.async {
                        if success {
                            isUnlocked = true
                        } else {
                            print("failed authentification")
                        }
                    }
                }
            } else {
                print("face id not available")
                 isUnlocked = true
            }
        }
    }
    
struct HomeView: View {
    @State private var newPass = false
    
    @Query var categories: [Category]
    @Environment(\.modelContext) var modelContext
  
    @State private var AddCategoryAlert = false
    @State private var newCategoryName = ""
    
    @State private var selectedCategory: Category? = nil
        
        var body: some View {
            NavigationStack {
                ZStack {
                    Color.black.ignoresSafeArea()
                    
                    ScrollView{
                        VStack (spacing: 16){
                            ForEach(categories){ category in
                                Button(action: {
                                    selectedCategory = category
                                }) {
                                    PasswordButtonRow(category: category
                                    )
                                }
                            }
                        }
                        .padding()
                    }
                    
                    VStack {
                        Spacer()
                        Button(action: {
                            AddCategoryAlert = true
                        }) {
                            Image(systemName: "folder.badge.plus")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Material.ultraThin)
                                .clipShape(Circle())
                        }
                    }
                    
                    .padding()
                    
                }
                .navigationTitle("Passwords")
                
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing){
                        
                        Button(action: {
                            newPass = true
                        }) {
                            
                            Image(systemName: "plus")
                                .padding(8)
                                .background(Material.ultraThin)
                                .clipShape(Circle())
                        }
                    }
                }
                
                .onAppear {
                    if categories.isEmpty {
                        let cat1 = Category(title: "Account and Log in", icon: "person.fill")
                        let cat2 = Category(title: "Administrative and IT", icon: "folder.fill")
                        let cat3 = Category(title: "Work and Business", icon: "briefcase.fill")
                        let cat4 = Category(title: "Social Media", icon: "globe.fill")
                                        
                        modelContext.insert(cat1)
                        modelContext.insert(cat2)
                        modelContext.insert(cat3)
                        modelContext.insert(cat4)
                   }
                }
                
                .alert("New category", isPresented: $AddCategoryAlert){
                    TextField("Category name", text: $newCategoryName)
                    
                    Button ("Add"){
                        let newCategory = Category(
                            title: newCategoryName,
                            icon: "folder.fill"
                        )
                        modelContext.insert(newCategory)
                        newCategoryName = ""
                    }
                    Button("Cancel", role: .cancel){
                        newCategoryName = ""
                    }
                    
                } message: {
                    Text("Write the name of a new category")
                }
                
                .sheet(isPresented: $newPass){
                    AddPasswordView()
                }
                
                .sheet(item: $selectedCategory) { category in
                    PasswordListView(category: category)
                }
            }
        }
    }

struct PasswordButtonRow: View {
    var category: Category
    
    var categoryColor: Color {
        switch category.title {
        case "Account and Log in": return .red
        case "Administrative and IT": return .orange
        case "Work and Business": return .yellow
        case "Social Media": return .brown
        default: return .purple
        }
    }
    
    var body: some View{
        HStack(spacing: 15){
            Image(systemName:  category.icon)
                .font(.title)
                .foregroundColor(.white)
                .padding(8)
                .background(categoryColor)
                .clipShape(Circle())
            
            Text(category.title)
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding(.vertical, 20)
        .padding(.horizontal)
        .background(Material.ultraThin)
        .cornerRadius(12)
    }
}

struct PasswordListView: View{
    var category: Category
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack{
            if category.passwords.isEmpty {
                VStack {
                    Spacer()
                    Text ("your list of \(category.title) passwords will appear here")
                        .foregroundStyle(.gray)
                    Spacer()
                    }
                .padding(.horizontal)
                } else {
                List(category.passwords) { password in
                    VStack(alignment: .leading) {
                        Text(password.name)
                            .font(.headline)
                        Text(password.passwordHash)
                            .font(.subheadline)
                            .foregroundStyle(.gray)
            }
            .navigationTitle(category.title)
            .navigationBarTitleDisplayMode(.inline)
                    
                    }
                }
            }
        }
    }

struct AddPasswordView: View {
    @Query var categories: [Category]
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var password: String = ""
    @State private var selectedCategory: Category?

    var body: some View {
        NavigationStack {
                Form {
                    Section("Details") {
                        TextField("Name", text: $name)
                        
                        Picker("Category", selection: $selectedCategory) {
                            
                            ForEach(categories) { category in
                                Text(category.title).tag(category as Category?)
                            }
                        }
                        .onAppear {
                            if selectedCategory == nil {
                                selectedCategory = categories.first
                            }
                        }
                    }
                    
                    Section("Credentials") {
                        SecureField("Password", text: $password)
                    }
                }
                .navigationTitle("New Password")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            let newPassword = PasswordItem(
                                name: name,
                                passwordHash: password,
                                category: selectedCategory
                            )
                            modelContext.insert(newPassword)
                            dismiss()
                        }
                        .disabled(name.isEmpty || password.isEmpty)
                    }
                }
            }
            .preferredColorScheme(.dark)
        }
    }

#Preview {
    ContentView()
        .modelContainer(for: [Category.self, PasswordItem.self], inMemory: true)
}
