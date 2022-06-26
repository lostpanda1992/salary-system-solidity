//作业：根据课程，使用我们写好的合约，连续10次添加employee，观察gas的变化，并用文字解释一下为什么会有这样的变化
//Authored by 陈宇 on: 2022年 06月 19日

pragma solidity ^0.4.14;

contract Payroll {

    uint constant payDuration = 10 seconds;

    struct Employee {
        address id;
        uint salary;
        uint lastPayday;
    }

    address owner;
    Employee[] employees;

    constructor() public { //构造函数 合约初步执行时会对其初始化
        owner = msg.sender;
    }

    function _partialPay(Employee employee) private{ // 内部函数 通过员工信息 负责支付薪水
        uint payment = employee.salary * ((now - employee.lastPayday) / payDuration); // 离职之前 清算薪水
        employee.id.transfer(payment);
    }

    function _findEmployee(address employeeId) private view returns (Employee, uint){ // 内部函数 通过员工地址找到员工
        for (uint i = 0; i < employees.length; i++){
            if (employees[i].id == employeeId) {
                return (employees[i], i);
            }
        }
    }

    // 增加员工
    function addEmployee(address employeeId, uint salary) public {
        require(msg.sender == owner);
        var(employee, index) = _findEmployee(employeeId);// 找到雇员 如果没有找到 则返回一个空的Employee类型的数组
        assert(employee.id == 0x0); // 判断是否为空员工 即没有该员工信息 如果没有 则执行下面函数 如果有 则退出

        employees.push(Employee(employeeId, salary * 1 ether, now));
    }

    // 删除雇员
    function removeEmployee(address employeeId) public {
        require(msg.sender == owner);
        var(employee, index) = _findEmployee(employeeId);// 找到雇员 如果没有找到 则返回一个空的Employee类型的数组

        assert(employee.id != 0x0); // 判断是否为空员工 即没有该员工信息 如果有 则执行下面函数 如果没有 则退出      

        //以下四句代码为找到该雇员信息后处理措施
        _partialPay(employee); 

        delete employees[index]; //删除该雇员

        employees[index] = employees[employees.length - 1];
        employees.length -= 1;
    }
    
    // 更新员工
    function updateEmployee(address employeeId, uint salary) public { 
        //查看msg.sender是不是当前owner 这里是雇主更新雇员的地方 防止雇员修改薪水
        require(msg.sender == owner);
        
        var(employee, index) = _findEmployee(employeeId);// 找到雇员 如果没有找到 则返回一个空的Employee类型的数组
        assert(employee.id != 0x0); // 判断是否为空员工 即没有该员工信息 如果有 则执行下面函数 如果没有 则退出 

        //如果已经存在 首先支付之前的薪水
         _partialPay(employee);
        //然后更新薪水和最后付薪水日期
        employees[index].salary = salary * 1 ether;
        employees[index].lastPayday = now;
    }

    function addFund() public payable returns (uint) {// 向合约中添加钱（以太）
        return address(this).balance ;
    }

    function calculateRollway() view public returns (uint) {// 计算能够支付多少月份的薪水
        uint totalSalary;
        //遍历所有员工获得总薪水
        for (uint i = 0; i < employees.length; i++){
            totalSalary += employees[i].salary;
        }
        return address(this).balance  / totalSalary;
    }

    function hasEnoughFund() view public returns (bool) {// 判断薪水是否足够
        return calculateRollway() > 0;
    }

    function getPaid() public{// 支付薪水，从合约向用户转账
        var(employee, index) = _findEmployee(msg.sender); // 这里的msg.sender为雇员 找到雇员 如果没有找到 则返回一个空的Employee类型的数组

        assert(employee.id != 0x0); // 判断是否为空员工 即没有该员工信息 如果有 则执行下面函数 如果没有 则退出   

        uint nextPayDay = employee.lastPayday + payDuration;
        assert(nextPayDay < now);

        employees[index].lastPayday = nextPayDay;
        employees[index].id.transfer(employee.salary);
    }
}