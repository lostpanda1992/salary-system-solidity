//完善智能合约的有效性 高效性 健壮性
// mapping替换list之后 添加（调用）雇员信息不会随着雇员数量越来越大
// Authored by 陈宇 on: 2022年 06月 23日

pragma solidity ^0.4.14;

import "./SafeMath.sol";
import "./Ownable.sol";

contract Payroll is Ownable{
    using SafeMath for uint;

    uint constant payDuration = 10 seconds;

    struct Employee {
        address id;
        uint salary;
        uint lastPayday;
    }

    //mapping不能作为合约的成员变量
    //mapping底层实现不使用数组+链表 不需要扩容 solidity的mapping实在storage（本质上就是一个无限大的hash表）上存储的 
    //无法简单地遍历整个mapping
    //当key不存在的时候 value=type's default
    mapping(address=>Employee) employee;

    uint totalSalary = 0; //状态变量 需要随时修改
    address owner;
    // Employee[] employees;
    mapping(address => Employee) public employees; // public 系统直接创造一个自动取值函数 可以替代checkEmployee函数

    // constructor() public { //构造函数 合约初步执行时会对其初始化
    //     owner = msg.sender;
    // }

    // modifier onlyOwner {
    //     require(msg.sender == owner);
    //     _;
    // }

    modifier employeeExits(address employeeId) { //判断员工是否存在
        var employee = employees[employeeId]; // 直接通过employeeId在mapping中找到对应的员工类型（struct）
        assert(employee.id != 0x0); // 判断是否为空员工 即没有该员工信息 如果没有 则执行下面函数 如果有 则退出
        _;
    }

    modifier deleteEmployee(address employeeId) { // 将员工从mapping中删除
        _;
        delete employees[employeeId]; //删除原地留下默认值
    }

    function _partialPay(Employee employee) private{ // 内部函数 通过员工信息 负责支付薪水
        uint payment = employee.salary * ((now - employee.lastPayday) / payDuration); // 离职之前 清算薪水
        employee.id.transfer(payment);
    }

    // function _findEmployee(address employeeId) private view returns (Employee, uint){ // 内部函数 通过员工地址找到员工
    //     for (uint i = 0; i < employees.length; i++){
    //         if (employees[i].id == employeeId) {
    //             return (employees[i], i);
    //         }
    //     }
    // }

    // 更改员工支付薪水地址
    function changePaymentAddress (address oldEmployeeId, address newEmployeeId) public onlyOwner employeeExits(oldEmployeeId) deleteEmployee(oldEmployeeId){

        // 通过mapping将旧的雇员信息赋值给新的薪水地址
        employees[newEmployeeId] = Employee(newEmployeeId, employees[oldEmployeeId].salary, now); //新的薪水地址，旧的雇员的salary(不变),lastPay更新成现在的时间

        // 删除旧的雇员信息，由于只是改变薪水地址 故不需要更新 totalSalary
        // 支付旧的雇员的薪水
        _partialPay(employees[oldEmployeeId]); 

        //删除原地留下默认值
        // delete employees[oldEmployeeId];
    }

    // 增加员工
    function addEmployee(address employeeId, uint salary) public onlyOwner {
        // require(msg.sender == owner);
        // var(employee, index) = _findEmployee(employeeId);// 找到雇员 如果没有找到 则返回一个空的Employee类型的数组
        var employee = employees[employeeId]; // 直接通过employeeId在mapping中找到对应的员工类型（struct）
        assert(employee.id == 0x0); // 判断是否为空员工 即没有该员工信息 如果没有 则执行下面函数 如果有 则退出

        // employees.push(Employee(employeeId, salary * 1 ether, now));
        employees[employeeId] = Employee(employeeId, salary * 1 ether, now); //向mapping中value赋值 value为Employee类型
        
        totalSalary += salary * 1 ether; //每添加一个员工就需要更新一次totalSalary
    }

    // 删除雇员
    function removeEmployee(address employeeId) public onlyOwner employeeExits(employeeId) deleteEmployee(employeeId){
        // require(msg.sender == owner);
        // var(employee, index) = _findEmployee(employeeId);// 找到雇员 如果没有找到 则返回一个空的Employee类型的数组
        var employee = employees[employeeId]; // 直接通过employeeId在mapping中找到对应的员工类型（struct）

        // assert(employee.id != 0x0); // 判断是否为空员工 即没有该员工信息 如果有 则执行下面函数 如果没有 则退出      

        //以下四句代码为找到该雇员信息后处理措施
        _partialPay(employee); 

        //支付薪水之后需要将该雇员的薪水从总薪水中删除
        totalSalary -= employees[employeeId].salary;

        // delete employees[index]; //通过delete删除该雇员 原地留下一个初始默认值（default）的元素
        // delete employees[employeeId]; //删除原地留下默认值

        //在mapping中通过key-value形式记录数据 故不需要顺序
        // employees[index] = employees[employees.length - 1]; //将list中最后一个元素赋值到delete删除元素的位置
        // employees.length -= 1; //list列表整体长度-1 
    }
    
    // 更新员工
    function updateEmployee(address employeeId, uint salary) public onlyOwner employeeExits(employeeId){ 
        //查看msg.sender是不是当前owner 这里是雇主更新雇员的地方 防止雇员修改薪水
        // require(msg.sender == owner);
        
        // var(employee, index) = _findEmployee(employeeId); // 找到雇员 如果没有找到 则返回一个空的Employee类型的数组
        var employee = employees[employeeId]; // 直接通过employeeId在mapping中找到对应的员工类型（struct）

        // assert(employee.id != 0x0); // 判断是否为空员工 即没有该员工信息 如果有 则执行下面函数 如果没有 则退出 

        //如果已经存在 首先支付之前的薪水
         _partialPay(employee);

        // //然后更新薪水和最后付薪水日期 通过list形式
        // employees[index].salary = salary * 1 ether;
        // employees[index].lastPayday = now;

        // 通过mappig形式更新薪水和最后付薪水日期 
        employees[employeeId].salary = salary * 1 ether;
        employees[employeeId].lastPayday = now;
    }

    function addFund() public payable returns (uint) {// 向合约中添加钱（以太）
        return address(this).balance ;
    }

    function calculateRollway() view public returns (uint) {// 计算能够支付多少月份的薪水

        // 由于mapping不好遍历整体内容 故需要通过空间换时间 将局部变量 totalSalary变成状态变量
        // //遍历list中所有员工获得总薪水
        // for (uint i = 0; i < employees.length; i++){
        //     totalSalary += employees[i].salary;
        // }
        return address(this).balance  / totalSalary;
    }

    function hasEnoughFund() view public returns (bool) {// 判断薪水是否足够
        return calculateRollway() > 0;
    }

    // //得到某一个员工的相关信息
    // function checkEmployee(address EmployeeId) returns (uint salary, uint lastPayday){
    //     var employee = employees[EmployeeId];
    //     salary = employee.salary;
    //     lastPayday = employee.lastPayday;
    // }

    function getPaid() public employeeExits(msg.sender) {// 支付薪水，从合约向用户转账
        // var(employee, index) = _findEmployee(msg.sender); // 这里的msg.sender为雇员 找到雇员 如果没有找到 则返回一个空的Employee类型的数组

        var employee = employees[msg.sender]; //通过mapping找到该雇员 msg.sender为函数调用方 这里的函数调用方为雇员
        // assert(employee.id != 0x0); // 判断是否为空员工 即没有该员工信息 如果有 则执行下面函数 如果没有 则退出   

        uint nextPayDay = employee.lastPayday + payDuration;
        assert(nextPayDay < now);

        // employees[index].lastPayday = nextPayDay; //更新最后付薪水日期
        // employees[index].id.transfer(employee.salary); //由合约向该雇员地址addres transfer(转移)薪水

        employees[msg.sender].lastPayday = nextPayDay; //更新最后付薪水日期
        employees[msg.sender].id.transfer(employee.salary); //由合约向该雇员地址addres transfer(转移)薪水

    }
}