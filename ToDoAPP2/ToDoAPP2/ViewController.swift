//
//  ViewController.swift
//  ToDoAPP2
//
//  Created by r on 05/12/2020.
//

import UIKit

struct Subject: Codable {
    let id: UUID?
    let title: String
}

struct Todo: Codable {
    let id: UUID?
    let title: String
    let finished: Bool
    let subjectid: UUID
}

struct Todo2: Codable {
    let title: String
    let finished: Bool
    let subjectid: UUID
}


class ViewController: UIViewController {
    
    var asignaturas: [Subject] = []
    var actividades: [Todo] = []
    var actividadesToShow: [Todo] = []
    var finished = false
    var selected: UUID?
    
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var tableView: UITableView!
    @IBAction func showFinished(_ sender: UIBarButtonItem) {
        finished = !finished
        showTasks()
    }
    
    @IBAction func add(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Nueva tarea",               message: "Añade una nueva tarea",                            preferredStyle: .alert)
                
                let saveAction = UIAlertAction(title: "Save", style: .default) {
                    [unowned self] action in
                    
                    guard let textField = alert.textFields?.first,
                        let nameToSave = textField.text else {
                            return
                    }
                    
                    self.addTask(title: nameToSave)
                }
                
                let cancelAction = UIAlertAction(title: "Cancel",                 style: .cancel)
                
                alert.addTextField()
                alert.addAction(saveAction)
                alert.addAction(cancelAction)
                
                present(alert, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        pickerView.delegate = self
        pickerView.dataSource = self
        getSubjects()
    }
    
    func showTasks() {
        actividadesToShow = finished ? actividades : actividades.filter({$0.finished == false})
        print(actividadesToShow)
        tableView.reloadData()
    }
    
    func getSubjects() {
        let url = URL(string: "http://127.0.0.1:8080/subjects")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let dataTask = URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error { print(error); return }
            do {
                self.asignaturas = try JSONDecoder().decode([Subject].self, from: data!)
                DispatchQueue.main.async {
                  self.pickerView.reloadAllComponents()
                    self.getTasks(subjectId: self.asignaturas[0].id!)
                    self.showTasks()
                }
            } catch { print(error) }
        }
        dataTask.resume()
    }
    
    func getTasks(subjectId: UUID) {
        let url = URL(string: "http://127.0.0.1:8080/todos/\(subjectId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let dataTask = URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error { print(error); return }
            do {
                self.actividades = try JSONDecoder().decode([Todo].self, from: data!)
                self.actividadesToShow = self.actividades
                print(!self.actividades.isEmpty ? self.actividades[0].title : "")
                DispatchQueue.main.async {
                    self.showTasks()
                }
            } catch { print(error) }
        }
        dataTask.resume()
    }
    
    func finishTask(task: Todo) {
        let url = URL(string: "http://127.0.0.1:8080/todos/\(task.id!)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        let dataTask = URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error { print(error); return }
            do {
                let actividad = try JSONDecoder().decode(Todo.self, from: data!)
                DispatchQueue.main.async {
                    self.getTasks(subjectId: actividad.subjectid)
                }
            } catch { print(error) }
        }
        dataTask.resume()
    }
    
    func deleteTask(task: Todo) {
        let url = URL(string: "http://127.0.0.1:8080/todos/\(task.id!)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        let dataTask = URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error { print(error); return }
            do {
                DispatchQueue.main.async {
                    self.getTasks(subjectId: task.subjectid)
                }
            }
        }
        dataTask.resume()
    }
    
    func addTask(title: String) {
        let url = URL(string: "http://127.0.0.1:8080/todos")
    
        // Add data to the model
        let uploadDataModel = Todo2 ( title: title, finished: false, subjectid: self.selected!)
        
        // Convert model to JSON data
        guard let jsonData = try? JSONEncoder().encode(uploadDataModel) else {
            print("Error: Trying to convert model to JSON data")
            return
        }
        // Create the url request
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type") // the request is JSON
        request.setValue("application/json", forHTTPHeaderField: "Accept") // the response expected to be in JSON format
        request.httpBody = jsonData
        request.httpMethod = "POST"
        let dataTask = URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error { print(error); return }
            do {
                DispatchQueue.main.async {
                    self.getTasks(subjectId: self.selected!)
                }
            }
        }
        dataTask.resume()
    }
}

// MARK: - UITableViewDataSource
extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return actividadesToShow.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let task = actividadesToShow[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = task.title
        if actividadesToShow[indexPath.row].finished == true {
            cell.selectionStyle = .none
            cell.textLabel?.textColor = UIColor.gray
        } else {
            cell.selectionStyle = .default
            cell.textLabel?.textColor = UIColor.black
        }
            return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if actividadesToShow[indexPath.row].finished == true {
            return false
        }
        return true
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        return UISwipeActionsConfiguration(actions: [
            UIContextualAction(style: .normal, title: "Finalizar") { (action, swipeButtonView, completion) in
                print("COMPLETE HERE")
                self.finishTask(task: self.actividadesToShow[indexPath.row])
                completion(true)
                //self.refresh()
                }
            ])
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        return UISwipeActionsConfiguration(actions: [
            UIContextualAction(style: .destructive, title: "Borrar") { (action, swipeButtonView, completion) in
                print("DELETE HERE")
                self.deleteTask(task: self.actividadesToShow[indexPath.row])
                completion(true)
                //self.refresh()
            }
            ])
    }
}

// MARK: - UIPickerViewDataSource
extension ViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return asignaturas.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return asignaturas[row].title
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.selected = asignaturas[row].id
        getTasks(subjectId:self.selected!)
        //refresh()
    }
}
