//
//  TodoTableViewController.swift
//  RealmExperiment
//
//  Created by Cali Castle  on 5/23/18.
//  Copyright © 2018 Cali Castle. All rights reserved.
//

import UIKit
import RealmSwift

class TodoTableViewController: UITableViewController {

    var todoList: ToDoList!
    
    var notificationToken: NotificationToken?
    
    override func viewDidLoad() {
        super.viewDidLoad()

//        navigationItem.rightBarButtonItem = self.editButtonItem
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewTodo(_:)))
        navigationItem.rightBarButtonItem = addButton
        
        title = todoList.name
        
        notificationToken = todoList.todos.observe { [weak self] changes in
            guard let tableView = self?.tableView else { return }
            
            switch changes {
            case .initial:
                // Results are now populated and can be accessed without blocking the UI
                tableView.reloadData()
            case .update(_, let deletions, let insertions, let modifications):
                // Query results have changed, so apply them to the UITableView
                tableView.performBatchUpdates({
                    tableView.insertRows(at: insertions.map({ IndexPath(row: $0, section: 0) }),
                                         with: .automatic)
                    tableView.deleteRows(at: deletions.map({ IndexPath(row: $0, section: 0)}), with: .automatic)
                    tableView.reloadRows(at: modifications.map({ IndexPath(row: $0, section: 0) }),
                                         with: .automatic)
                }, completion: nil)
            case .error(let error):
                // An error occurred while opening the Realm file on the background worker thread
                fatalError("\(error)")
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc
    fileprivate func insertNewTodo(_ sender: Any) {
        let alertController = UIAlertController(title: "Enter name for a task", message: nil, preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "Task goal"
            textField.autocapitalizationType = .sentences
            textField.returnKeyType = .done
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "Add", style: .default, handler: { _ in
            self.saveTodo(name: alertController.textFields?.first?.text)
        }))
        
        present(alertController, animated: true, completion: nil)
    }

    fileprivate func saveTodo(name: String?) {
        guard let name = name else { return }
        
        let newTodo = ToDo.make()
        newTodo.goal = name
        
        let database = DatabaseManager.main.database
        
        do {
            try database.write {
                database.add(newTodo)
                todoList.todos.append(newTodo)
            }
        } catch let error as NSError {
            print("Error when writing database:\n\(error.localizedDescription)")
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todoList.todos.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? nil : "Completed"
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TodoCell", for: indexPath)

        // Configure the cell...
        let todo = todoList.todos[indexPath.row]
        
        cell.textLabel?.text = todo.goal
        cell.accessoryType = todo.completedAt == nil ? .none : .checkmark
        
        return cell
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }

}
