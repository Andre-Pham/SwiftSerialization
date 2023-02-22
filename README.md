# SwiftSerialization
A package used for serializing and restoring Swift objects.

## Database Transaction Examples

*For class definitions, refer to **Storable Class Examples**.*

Any object that conforms to `Storable` can easily be written to and read from the database.

```swift
// Lets define a database first.
// Realistically this would be managed at the application level.
let database: DatabaseTarget = SQLiteDatabase()

// Here's the object we want to read/write.
let person = Person(name: "Andre", age: 21)

// Two ways to write to the database. 
// .write returns the outcome of the transaction (true = success, false = failure)
database.write(Record(id: "myID", data: person))
database.write(Record(data: person))

// Reading from the database.
let readPerson: Person? = database.read(id: "myID")
let readPeople: [Person] = database.read() // Reads all saved Person objects

// Count all records in the database.
let count = database.count()

// Delete either by id or by type.
database.delete(id: "myID") // Returns true if any record was deleted
database.delete(Person.self) // Returns number of records deleted

// Or just delete everything.
database.clearDatabase() // Returns number of records deleted
```

Everything works asyncronously.

```swift
DispatchQueue.global().async {
    let readPerson: Person? = database.read(id: "myID")
    DispatchQueue.main.async {
        // Update UI when done
    }
}
```

## Storable Class Examples

Class definitions, and how you would conform them to `Storable` to be serialized.

```swift
class Person: Storable {
    
    private(set) var firstName: String
    private(set) var lastName: String
    public let id = UUID()
    
    init(firstName: String, lastName: String) {
        self.firstName = firstName
        self.lastName = lastName
    }
    
    // MARK: - Serialization
    
    private enum Field: String {
        case firstName
        case lastName
    }
    
    required init(dataObject: DataObject) {
        self.firstName = dataObject.get(Field.firstName.rawValue)
        self.lastName = dataObject.get(Field.lastName.rawValue)
        // NOTE: You can also override the default return value if the value can't be found
        // self.lastName = dataObject.get(Field.lastName.rawValue, onFail: "MISSING")
    }
    
    func toDataObject() -> DataObject {
        return DataObject(self)
            .add(key: Field.firstName.rawValue, value: self.firstName)
            .add(key: Field.lastName.rawValue, value: self.lastName)
    }
    
}

class Student: Person {
    
    private(set) var homework = [Homework]()
    private(set) var debt: Double
    private(set) var teacher: Teacher
    private(set) var subjectNames: [String]
    
    init(firstName: String, lastName: String, debt: Double, teacher: Teacher, subjectNames: [String]) {
        self.debt = debt
        self.teacher = teacher
        self.subjectNames = subjectNames
        super.init(firstName: firstName, lastName: lastName)
    }
    
    func giveHomework(_ homework: Homework) {
        self.homework.append(homework)
    }
    
    // MARK: - Serialization
    
    private enum Field: String {
        case debt
        case homework
        case teacher
        case subjectNames
    }
    
    required init(dataObject: DataObject) {
        self.debt = dataObject.get(Field.debt.rawValue)
        self.homework = dataObject.getObjectArray(Field.homework.rawValue, type: Homework.self)
        self.teacher = dataObject.getObject(Field.teacher.rawValue, type: Teacher.self)
        self.subjectNames = dataObject.get(Field.subjectNames.rawValue)
        super.init(dataObject: dataObject)
    }
    
    override func toDataObject() -> DataObject {
        return super.toDataObject()
            .add(key: Field.debt.rawValue, value: self.debt)
            .add(key: Field.homework.rawValue, value: self.homework)
            .add(key: Field.teacher.rawValue, value: self.teacher)
            .add(key: Field.subjectNames.rawValue, value: self.subjectNames)
    }
    
}

class Teacher: Person {
    
    private(set) var salary: Double
    
    init(firstName: String, lastName: String, salary: Double) {
        self.salary = salary
        super.init(firstName: firstName, lastName: lastName)
    }
    
    // MARK: - Serialization
    
    private enum Field: String {
        case salary
    }
    
    required init(dataObject: DataObject) {
        self.salary = dataObject.get(Field.salary.rawValue)
        super.init(dataObject: dataObject)
    }
    
    override func toDataObject() -> DataObject {
        return super.toDataObject()
            .add(key: Field.salary.rawValue, value: self.salary)
    }
    
}

class Homework: Storable {
    
    public let answers: String
    public var grade: Int?
    
    init(answers: String, grade: Int?) {
        self.answers = answers
        self.grade = grade
    }
    
    // MARK: - Serialization
    
    private enum Field: String {
        case answers
        case grade
    }
    
    required init(dataObject: DataObject) {
        self.answers = dataObject.get(Field.answers.rawValue)
        self.grade = dataObject.get(Field.grade.rawValue)
    }
    
    func toDataObject() -> DataObject {
        return DataObject(self)
            .add(key: Field.answers.rawValue, value: self.answers)
            .add(key: Field.grade.rawValue, value: self.grade)
    }
    
}
```

Serialization works with `typealias` definitions, but the syntax is a little different.

```swift
class Person // ...
protocol HasDebt // ...

typealias Student = Person & HasDebt

// ...

// In init(dataObject: DataObject)
self.students = dataObject.getObjectArray(Field.students.rawValue, type: Person.self) as! [any Student]

// In toDataObject() -> DataObject
.add(key: Field.students.rawValue, value: self.students as [Person])
```

