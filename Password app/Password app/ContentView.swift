import SwiftUI
import SwiftData

// --- 1. IL MODELLO DATI ---
// Qui definiamo come è fatta una "password"
// nel nostro database SwiftData.
@Model
final class PasswordEntry {
    var name: String
    var username: String
    var website: String
    var password: String // Per ora lo salviamo in chiaro
    var createdAt: Date

    init(name: String, username: String, website: String, password: String, createdAt: Date = .now) {
        self.name = name
        self.username = username
        self.website = website
        self.password = password
        self.createdAt = createdAt
    }
}


// --- 2. LA VISTA "AGGIUNGI" ---
struct AddPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // Dati del form
    @State private var name: String = ""
    @State private var username: String = ""
    @State private var website: String = ""
    @State private var password: String = ""
    
    // Controlla se il form è valido
    private var isFormValid: Bool {
        !name.isEmpty && !password.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name (e.g., 'Google Account')", text: $name)
                    TextField("Username or Email", text: $username)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    TextField("Website (e.g., 'google.com')", text: $website)
                        .keyboardType(.URL)
                }
                
                Section("Password") {
                    SecureField("Password", text: $password)
                }
            }
            .navigationTitle("New Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        savePassword()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private func savePassword() {
        // 1. Crea il nuovo oggetto
        let newEntry = PasswordEntry(
            name: name,
            username: username,
            website: website,
            password: password
        )
        
        // 2. Salvalo nel database SwiftData
        modelContext.insert(newEntry)
        
        // 3. Chiudi la vista
        dismiss()
    }
}


// --- 3. LA VISTA PRINCIPALE "CONTENTVIEW" ---
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    // Carica *tutte* le password dal database
    @Query(sort: \PasswordEntry.name) private var allEntries: [PasswordEntry]
    
    @State private var isShowingAddSheet = false
    @State private var searchText = ""
    
    // Filtra le password in base alla ricerca
    var filteredPasswords: [PasswordEntry] {
        if searchText.isEmpty {
            return allEntries // Mostra tutto
        } else {
            return allEntries.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.username.localizedCaseInsensitiveContains(searchText) ||
                $0.website.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // La nostra lista
                List {
                    ForEach(filteredPasswords) { entry in
                        VStack(alignment: .leading) {
                            Text(entry.name).font(.headline)
                            Text(entry.username.isEmpty ? "No Username" : entry.username)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onDelete(perform: deleteEntries)
                }
                
                // Messaggio di "Stato Vuoto"
                if allEntries.isEmpty {
                    EmptyStateView()
                }
            }
            .navigationTitle("Passwords") // Titolo in alto
            .toolbar {
                // Pulsante "+" in alto a destra
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        isShowingAddSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
                
                // Barra di ricerca in basso
                ToolbarItem(placement: .bottomBar) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search Passwords", text: $searchText)
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary.opacity(0.7))
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.black)
                    .colorScheme(.dark)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.bottom, 5)
                }
            }
        }
        .sheet(isPresented: $isShowingAddSheet) {
            AddPasswordView()
        }
    }
    
    // Funzione per eliminare
    private func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            let entry = filteredPasswords[index]
            modelContext.delete(entry)
        }
    }
}


// --- 4. VISTA PER LO STATO VUOTO ---
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "key.fill")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.6))
                .padding(.bottom, 10)
            
            Text("No Passwords")
                .font(.headline)
                .fontWeight(.bold)
            
            Text("Tap the + button to create your first password.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 50)
        }
        .allowsHitTesting(false) // Fa in modo che non blocchi i click
    }
}


// --- 5. IL PUNTO DI INGRESSO DELL'APP ---
@main
struct Password_appApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // "Inietta" il database SwiftData in ContentView
        .modelContainer(for: PasswordEntry.self)
    }
}


// --- 6. PREVIEW PER LE VISTE ---
// (Queste servono solo per l'anteprima in Xcode)

#Preview("Content View") {
    do {
        let schema = Schema([PasswordEntry.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        
        // Dati finti per l'anteprima
        let exampleEntry = PasswordEntry(name: "Google Account", username: "example@gmail.com", website: "google.com", password: "123")
        container.mainContext.insert(exampleEntry)
        
        return ContentView()
            .modelContainer(container)
        
    } catch {
        return Text("Failed to create preview container: \(error.localizedDescription)")
    }
}

#Preview("Add Password View") {
    AddPasswordView()
        .modelContainer(for: PasswordEntry.self, inMemory: true)
}
