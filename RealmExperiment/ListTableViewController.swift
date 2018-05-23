//
//  MasterViewController.swift
//  RealmExperiment
//
//  Created by Cali Castle on 5/14/18.
//  Copyright © 2018 Cali Castle. All rights reserved.
//

import UIKit
import Bond
import RealmSwift

class ListTableViewController: UITableViewController {
    
    lazy var todoLists: Results<ToDoList> = {
        return DatabaseManager.main.database.objects(ToDoList.self)
    }()
    
    var notificationToken: NotificationToken?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        navigationItem.leftBarButtonItem = editButtonItem

        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewList(_:)))
        navigationItem.rightBarButtonItem = addButton
        
        tableView.allowsSelectionDuringEditing = true
        tableView.tableFooterView = UIView()
        
        notificationToken = todoLists.observe { [weak self] changes in
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
                self?.updateTitle()
            case .error(let error):
                // An error occurred while opening the Realm file on the background worker thread
                fatalError("\(error)")
            }
        }
        
        updateTitle()
    }

    deinit {
        notificationToken?.invalidate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    fileprivate func updateTitle() {
        title = "Todo Lists (\(todoLists.count))"
    }

    @objc
    func insertNewList(_ sender: Any) {
        let alertController = UIAlertController(title: "Enter name for todo list", message: nil, preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "List name"
            textField.autocapitalizationType = .sentences
            textField.returnKeyType = .done
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "Add", style: .default, handler: { _ in
            self.saveTodoList(name: alertController.textFields?.first?.text)
        }))
        
        present(alertController, animated: true, completion: nil)
    }
    
    fileprivate func saveTodoList(name: String?) {
        guard let name = name else { return }
        
        let newList = ToDoList.make()
        newList.name = name
        
        let database = DatabaseManager.main.database
        
        do {
            try database.write {
                database.add(newList)
            }
        } catch let error as NSError {
            print("Error when writing database:\n\(error.localizedDescription)")
        }
    }
    
    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todoLists.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        let list = todoLists[indexPath.row]
        cell.textLabel?.text = list.name
        cell.detailTextLabel?.text = "\(list.todos.count) Todos"
        
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let list = todoLists[indexPath.row]
        
        guard tableView.isEditing else {
            performSegue(withIdentifier: "ShowTodo", sender: list)
            
            return
        }
        
        let alertController = UIAlertController(title: "Update name for todo list", message: nil, preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "List name"
            textField.text = list.name
            textField.autocapitalizationType = .sentences
            textField.returnKeyType = .done
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "Update", style: .default, handler: { _ in
            try? DatabaseManager.main.database.write {
                list.name = alertController.textFields?.first?.text ?? ""
            }
        }))
        
        present(alertController, animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let list = todoLists[indexPath.row]
            
            let database = DatabaseManager.main.database
            try? database.write {
                database.delete(list)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else { return }
        
        if identifier == "ShowTodo", let list = sender as? ToDoList, let destination = segue.destination as? TodoTableViewController {
            destination.todoList = list
        }
    }

}

