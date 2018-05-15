//
//  MasterViewController.swift
//  RealmExperiment
//
//  Created by Cali Castle on 5/14/18.
//  Copyright © 2018 Cali Castle. All rights reserved.
//

import UIKit
import RealmSwift

class MasterViewController: UITableViewController {

    lazy var realm: Realm? = {
        guard let realm = try? Realm() else { fatalError("Realm failed") }
        
        return realm
    }()
    
    lazy var todos: Results<Todo> = {
        return realm!.objects(Todo.self)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        navigationItem.leftBarButtonItem = editButtonItem

        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewTodo(_:)))
        navigationItem.rightBarButtonItem = addButton
        
        tableView.allowsSelectionDuringEditing = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    @objc
    func insertNewTodo(_ sender: Any) {
        let alertController = UIAlertController(title: "Enter name for todo item", message: nil, preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "Todo item"
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
        
        let newTodo = Todo()
        newTodo.name = name
        
        try? realm?.write {
            realm?.add(newTodo)
        }
        
        tableView.reloadSections([0, 1], with: .automatic)
    }

    fileprivate func filteredTodos(finished: Bool) -> [Todo] {
        return todos.filter({ return $0.finished == finished })
    }
    
    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return todos.count == 0 ? 0 : 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todos.filter({ return $0.finished == (section != 0) }).count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "New Items" : "Finished"
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        let todo = filteredTodos(finished: indexPath.section == 1)[indexPath.row]
        cell.textLabel?.text = todo.name
        cell.accessoryType = todo.finished ? .checkmark : .none
        
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let todo = filteredTodos(finished: indexPath.section == 1)[indexPath.row]
        
        if tableView.isEditing {
            let alertController = UIAlertController(title: "Update name for todo item", message: nil, preferredStyle: .alert)
            alertController.addTextField { textField in
                textField.placeholder = "Todo item"
                textField.text = todo.name
                textField.autocapitalizationType = .sentences
                textField.returnKeyType = .done
            }
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: "Add", style: .default, handler: { _ in
                try? self.realm?.write {
                    todo.name = alertController.textFields?.first?.text ?? ""
                }
            }))
            
            present(alertController, animated: true, completion: nil)
        } else {
            try? realm?.write {
                todo.finished = !todo.finished
            }
        }
        
        tableView.reloadSections([0, 1], with: .automatic)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let todo = filteredTodos(finished: indexPath.section == 1)[indexPath.row]
            
            try? realm?.write {
                realm?.delete(todo)
            }
            
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }


}

