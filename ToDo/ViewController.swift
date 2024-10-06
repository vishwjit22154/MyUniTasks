import UIKit

// TodoItem class conforming to Codable for saving and loading
class TodoItem: Codable {
    var title: String
    var dueDate: Date?
    
    init(title: String, dueDate: Date?) {
        self.title = title
        self.dueDate = dueDate
    }
}

class TodoListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var tableView: UITableView!
    var todoItems: [TodoItem] = []  // Array to store tasks
    
    // Key for storing data in UserDefaults
    let todoItemsKey = "todoItemsKey"
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load tasks from UserDefaults
        loadTodoItems()
        
        title = "My Uni"
        view.backgroundColor = .black
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.green]
        navigationController?.navigationBar.barTintColor = .black
        navigationController?.navigationBar.tintColor = .green

        setupTableView()
        setupAddButton()
    }
    
    // Set up the TableView
    func setupTableView() {
        tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "TodoCell")
        tableView.backgroundColor = .black
        tableView.separatorColor = .green
        view.addSubview(tableView)
    }
    
    // Set up the Add Button
    func setupAddButton() {
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNewTodo))
        addButton.tintColor = .green
        navigationItem.rightBarButtonItem = addButton
    }
    
    // Save tasks to UserDefaults
    func saveTodoItems() {
        let encoder = JSONEncoder()
        if let encodedData = try? encoder.encode(todoItems) {
            UserDefaults.standard.set(encodedData, forKey: todoItemsKey)
        }
    }
    
    // Load tasks from UserDefaults
    func loadTodoItems() {
        if let savedData = UserDefaults.standard.data(forKey: todoItemsKey) {
            let decoder = JSONDecoder()
            if let decodedItems = try? decoder.decode([TodoItem].self, from: savedData) {
                todoItems = decodedItems
            }
        }
    }
    
    // Add a new to-do item
    @objc func addNewTodo() {
        let alertController = UIAlertController(title: "New To-Do", message: "Enter a new to-do item", preferredStyle: .alert)
        
        let titleString = NSAttributedString(string: "New To-Do", attributes: [NSAttributedString.Key.foregroundColor : UIColor.green])
        let messageString = NSAttributedString(string: "Enter a new to-do item", attributes: [NSAttributedString.Key.foregroundColor : UIColor.green])
        alertController.setValue(titleString, forKey: "attributedTitle")
        alertController.setValue(messageString, forKey: "attributedMessage")
        
        alertController.addTextField { textField in
            textField.placeholder = "To-Do item"
            textField.backgroundColor = .black
            textField.textColor = .green
        }
        
        let nextAction = UIAlertAction(title: "Next", style: .default) { [weak self] _ in
            guard let textField = alertController.textFields?.first, let newItemTitle = textField.text, !newItemTitle.isEmpty else {
                return
            }
            self?.showDatePicker(for: newItemTitle)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        nextAction.setValue(UIColor.green, forKey: "titleTextColor")
        cancelAction.setValue(UIColor.green, forKey: "titleTextColor")
        
        alertController.addAction(nextAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    // Show DatePicker for due date
    func showDatePicker(for newItemTitle: String) {
        let alertController = UIAlertController(title: "Select Due Date", message: nil, preferredStyle: .alert)
        
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .dateAndTime
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.minimumDate = Date()
        
        alertController.view.addSubview(datePicker)
        
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        datePicker.centerXAnchor.constraint(equalTo: alertController.view.centerXAnchor).isActive = true
        datePicker.topAnchor.constraint(equalTo: alertController.view.topAnchor, constant: 50).isActive = true
        datePicker.widthAnchor.constraint(equalTo: alertController.view.widthAnchor, constant: -20).isActive = true
        datePicker.heightAnchor.constraint(equalToConstant: 200).isActive = true
        
        let doneAction = UIAlertAction(title: "Done", style: .default) { [weak self] _ in
            let newItem = TodoItem(title: newItemTitle, dueDate: datePicker.date)
            self?.todoItems.append(newItem)
            self?.sortTodoItems()
            self?.tableView.reloadData()
            self?.saveTodoItems()  // Save the new task
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        doneAction.setValue(UIColor.green, forKey: "titleTextColor")
        cancelAction.setValue(UIColor.green, forKey: "titleTextColor")
        
        alertController.addAction(doneAction)
        alertController.addAction(cancelAction)
        
        let heightConstraint = NSLayoutConstraint(item: alertController.view!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 350)
        alertController.view.addConstraint(heightConstraint)
        
        present(alertController, animated: true, completion: nil)
    }
    
    // Sort tasks by due date
    func sortTodoItems() {
        todoItems.sort { item1, item2 in
            guard let date1 = item1.dueDate, let date2 = item2.dueDate else { return false }
            return date1 < date2
        }
    }
    
    // UITableViewDataSource Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todoItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TodoCell", for: indexPath)
        let todoItem = todoItems[indexPath.row]
        
        cell.backgroundColor = .black
        cell.textLabel?.textColor = .green
        
        if let dueDate = todoItem.dueDate {
            cell.textLabel?.text = "\(todoItem.title) - \(dateFormatter.string(from: dueDate))"
        } else {
            cell.textLabel?.text = todoItem.title
        }
        
        return cell
    }
    
    // Enable swipe to delete
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            todoItems.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            saveTodoItems()  // Save after deletion
        }
    }
}

