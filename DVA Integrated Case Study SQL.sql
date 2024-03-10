--TASK 1


create database Loans;


select * from sys.databases;


select table_name from INFORMATION_SCHEMA.TABLES;


select top 5 * from Banker_Data;
select top 5 * from Customer_Data;
select top 5 * from Home_Loan_Data;
select top 5 * from Loan_Records_Data;


--TASK 2


-- Q1) Find the average age of male bankers (years, rounded to 1 decimal place) based on the date they joined WBG 


select round(avg(DATEDIFF(year,dob,t1.date_joined)),1) as average_age from Banker_Data as t1
where t1.gender = 'male';


-- Q2)  Find the total number of different cities for which home loans have been issued. 


select count(distinct t1.city) as total_num_cities from Home_Loan_Data as t1
where t1.joint_loan = 1;


-- Q3) Find the customer ID, first name, last name, and email of customers whose email address contains the term 'amazon'.


select customer_id,first_name,last_name,email from Customer_Data as t1
where email like '%amazon%';


-- Q4)  Find the names of the top 3 cities (based on descending alphabetical order) and corresponding loan percent 
-- (in ascending order) with the lowest average loan percent.


select city from(
select top 3 city,AVG(loan_percent) as AVG_loanpercent from Home_Loan_Data as t1
group by city
order by AVG_loanpercent asc,city desc) as a;


-- Q5) Find the city name and the corresponding average property value (using appropriate alias) 
-- for cities where the average property value is greater than $3,000,000


select city,AVG(t1.property_value) as avg_property_value from Home_Loan_Data as t1
group by city
having avg(property_value) > 3000000;

-- Q6)  Find the average age (at the point of loan transaction, in years and nearest integer) 
-- of female customers who took a non-joint loan for townhomes


select AVG(DATEDIFF(YEAR,t1.dob,t2.transaction_date)) as avg_age from Customer_Data as t1
join Loan_Records_Data as t2
on t1.customer_id = t2.customer_id
join Home_Loan_Data as t3
on t2.loan_id = t3.loan_id
where t1.gender = 'female' and t3.joint_loan = 0 and t3.property_type = 'townhome';



-- Q7) Find the maximum property value (using appropriate alias) of each property type,
-- ordered by the maximum property value in descending order


select property_type,MAX(t1.property_value)as max_property_value from Home_Loan_Data as t1
group by property_type
order by max_property_value desc;


-- Q8)   Find the number of home loans issued in San Francisco. 


select count(city) as num_city from Home_Loan_Data as t1
where t1.city = 'San Francisco';


-- Q9) Find the ID, first name, and last name of the top 2 bankers (and corresponding transaction count) 
-- involved in the highest number of distinct loan records.


select top 2 t1.banker_id,first_name,last_name,COUNT(distinct t2.loan_id) as loan_records from Banker_Data as t1
join Loan_Records_Data as t2
on t1.banker_id = t2.banker_id
group by t1.banker_id,first_name,last_name
order by loan_records desc;


-- Q10) Find the average loan term for loans not for semi-detached and townhome property types,
-- and are in the following list of cities: Sparks, Biloxi, Waco, Las Vegas, and Lansing


select AVG(t1.loan_term) as avg_loan_term from Home_Loan_Data as t1
where property_type  not in	('semi-detached','townhome') and city 
in ('Sparks', 'Biloxi', 'Waco', 'Las Vegas', 'Lansing');



--TASK 3


--Q1) Find the ID and full name (first name concatenated with last name) of 
--customers who were served by bankers aged below 30 (as of 1 Aug 2022).


select t1.customer_id,CONCAT(t1.first_name,' ',t1.last_name) as full_name from Customer_Data as t1
join Loan_Records_Data as t2 on t1.customer_id = t2.customer_id
join Banker_Data as t3 on t2.banker_id = t3.banker_id
where DATEDIFF(YEAR,t3.dob,'2022-08-01')<30;


--Q2) Create a stored procedure called recent_joiners that returns the ID, 
--concatenated full name, date of birth, and join date of bankers who joined within the recent 2 years (as of 1 Sep 2022) 
--Call the stored procedure recent_joiners you created above.


create procedure recent_joiners as
select banker_id, concat(first_name,' ',last_name)Full_name,dob,date_joined 
from Banker_Data as a
where date_joined >= dateadd(YEAR,-2,'2022-09-01')
go

exec recent_joiners;


--Q3) Find the number of bankers involved in loans 
--where the loan amount is greater than the average loan amount.


select count(distinct banker_id) as num_bankers from(
select t3.banker_id,(property_value*loan_percent/100) as loan_amt from Home_Loan_Data as t1
join Loan_Records_Data as t2 on t1.loan_id = t2.loan_id
join Banker_Data as t3 on t2.banker_id = t3.banker_id
group by t3.banker_id,(property_value*loan_percent/100)
having (property_value*loan_percent/100) > (select AVG((property_value*loan_percent/100)) from Home_Loan_Data))a



--Q4) Find the ID, first name and last name of customers with properties of value between $1.5 and $1.9 million, along with a new column 'tenure' 
--that categorizes how long the customer has been with WBG. The 'tenure' column is based on the following logic:
--Long: Joined before 1 Jan 2015
--Mid: Joined on or after 1 Jan 2015, but before 1 Jan 2019
--Short: Joined on or after 1 Jan 2019.


select t1.customer_id,first_name,last_name, 
case when t1.customer_since < '2015-01-01' then 'Long'
when t1.customer_since > '2015-01-01' and t1.customer_since < '2019-01-01' then 'Mid'
else 'Short' end as tenure
from Customer_Data as t1
join Loan_Records_Data as t2 on t1.customer_id = t2.customer_id
join Home_Loan_Data as t3 on t2.loan_id = t3.loan_id
where property_value between 1500000 and 1900000;



--Q5) Find the number of Chinese customers with joint loans with property values 
--less than $2.1 million, and served by female bankers.


select COUNT(nationality) as num_chinese_cust from Customer_Data as t1
join Loan_Records_Data as t2 on t1.customer_id = t2.customer_id
join Home_Loan_Data as t3 on t2.loan_id = t3.loan_id
join Banker_Data as t4 on t2.banker_id = t4.banker_id
where nationality = 'china' and joint_loan = 1 and property_value < 2100000 and t4.gender = 'female';



--Q6) Create a view called dallas_townhomes_gte_1m which returns all the details of 
--loans involving properties of townhome type, located in Dallas, 
--and have loan amount of >$1 million.

create view  DALLAS_TOWNHOMES_GTE_1M as
select property_type, city, (property_value * loan_percent/100)loan_amount 
from Home_Loan_Data as d1
where property_value > 1000000 and property_type = 'townhome' and city = 'Dallas'

select * from DALLAS_TOWNHOMES_GTE_1M;



--Q7) Create a stored procedure called city_and_above_loan_amt that takes in two parameters (city_name, loan_amt_cutoff) that returns the full details 
--of customers with loans for properties in the input city and 
--with loan amount greater than or equal to the input loan amount cutoff.  
--Call the stored procedure city_and_above_loan_amt you 
--created above, based on the city San Francisco and loan amount cutoff of $1.5 million


create procedure city_and_above_loan_amts  @city varchar(255),@loan_amt_cutoff decimal(12,2) as

select * from Customer_Data as t1
join Loan_Records_Data as t2 on t1.customer_id = t2.customer_id
join Home_Loan_Data as t3 on t2.loan_id = t3.loan_id
where city = @city and (property_value*loan_percent/100)>= @loan_amt_cutoff 
go

exec city_and_above_loan_amts @city = 'San Francisco', @loan_amt_cutoff = 1500000



--Q8) Find the top 3 transaction dates (and corresponding loan amount sum) for which 
--the sum of loan amount issued on that date is the highest.


select top 3 transaction_date,sum(property_value*loan_percent/100) as loan_amt from Loan_Records_Data as t1
join Home_Loan_Data as t2 on t1.loan_id = t2.loan_id
group by transaction_date
order by loan_amt desc;



--Q9) Find the sum of the loan amounts ((i.e., property value x loan percent / 100) 
--for each banker ID, excluding properties based in the cities of Dallas and Waco. 
--The sum values should be rounded to nearest integer.


 select t3.banker_id,round(sum(property_value*loan_percent/100),0) as loan_amt from Home_Loan_Data as t1
 join Loan_Records_Data as t2 on t1.loan_id = t2.loan_id
 join Banker_Data as t3 on t2.banker_id = t3.banker_id
 where city not in ('Dallas','Waco')
 group by t3.banker_id;