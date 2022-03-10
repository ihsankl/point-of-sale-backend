-- phpMyAdmin SQL Dump
-- version 5.1.1
-- https://www.phpmyadmin.net/
--
-- Host: db
-- Generation Time: Mar 09, 2022 at 12:27 PM
-- Server version: 10.6.5-MariaDB-1:10.6.5+maria~focal
-- PHP Version: 7.4.27

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `point_of_sale`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`admin`@`%` PROCEDURE `populate` (`in_db` VARCHAR(50), `in_table` VARCHAR(50), `in_rows` INT, `in_debug` CHAR(1))  BEGIN


DECLARE col_name VARCHAR(100);
DECLARE col_type VARCHAR(100);
DECLARE col_datatype VARCHAR(100);
DECLARE col_maxlen VARCHAR(100);
DECLARE col_extra VARCHAR(100);
DECLARE col_num_precision VARCHAR(100);
DECLARE col_num_scale VARCHAR(100);
DECLARE func_query VARCHAR(1000);
DECLARE i INT;
DECLARE batch_size INT;

DECLARE done INT DEFAULT 0;
DECLARE cur_datatype cursor FOR
 SELECT column_name,COLUMN_TYPE,data_type,CHARACTER_MAXIMUM_LENGTH,EXTRA,NUMERIC_PRECISION,NUMERIC_SCALE FROM information_schema.columns WHERE table_name=in_table AND table_schema=in_db;
DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;


SET func_query='';
OPEN cur_datatype;
datatype_loop: loop

FETCH cur_datatype INTO col_name, col_type, col_datatype, col_maxlen, col_extra, col_num_precision, col_num_scale;

  IF (done = 1) THEN
    leave datatype_loop;
  END IF;

CASE
WHEN col_extra='auto_increment' THEN SET func_query=concat(func_query,'NULL, ');
WHEN col_datatype in ('double','int','bigint') THEN SET func_query=concat(func_query,'get_int(), ');
WHEN col_datatype in ('varchar','char') THEN SET func_query=concat(func_query,'get_string(',ifnull(col_maxlen,0),'), ');
WHEN col_datatype in ('tinyint', 'smallint','year') or col_datatype='mediumint' THEN SET func_query=concat(func_query,'get_tinyint(), ');
WHEN col_datatype in ('datetime','timestamp') THEN SET func_query=concat(func_query,'get_datetime(), ');
WHEN col_datatype in ('date') THEN SET func_query=concat(func_query,'get_date(), ');
WHEN col_datatype in ('float', 'decimal') THEN SET func_query=concat(func_query,'get_float(',col_num_precision,',',col_num_scale,'), ');
WHEN col_datatype in ('enum','set') THEN SET func_query=concat(func_query,'get_enum("',col_type,'"), ');
WHEN col_datatype in ('GEOMETRY','POINT','LINESTRING','POLYGON','MULTIPOINT','MULTILINESTRING','MULTIPOLYGON','GEOMETRYCOLLECTION') THEN SET func_query=concat(func_query,'NULL, ');
ELSE SET func_query=concat(func_query,'get_varchar(',ifnull(col_maxlen,0),'), ');
END CASE;


end loop  datatype_loop;
close cur_datatype;

SET func_query=trim(trailing ', ' FROM func_query);
SET @func_query=concat("INSERT INTO ", in_db,".",in_table," VALUES (",func_query,");");
SET @func_query=concat("INSERT IGNORE  INTO ", in_db,".",in_table," VALUES (",func_query,")");

SET batch_size = 500;
while batch_size > 0 DO
   set batch_size  = batch_size - 1;
   set @func_query = CONCAT( @func_query , " ,(",func_query,")" );
END WHILE;
set @func_query = CONCAT( @func_query , ";" );
        IF in_debug='Y' THEN
                select @func_query;
        END IF;
SET i=in_rows;
SET batch_size=500;
populate :loop
        WHILE (i>batch_size) DO
          PREPARE t_stmt FROM @func_query;
          EXECUTE t_stmt;
          SET i = i - batch_size;
        END WHILE;
SET @func_query=concat("INSERT INTO ", in_db,".",in_table," VALUES (",func_query,");");
        WHILE (i>0) DO
          PREPARE t_stmt FROM @func_query;
          EXECUTE t_stmt;
          SET i = i - 1;
        END WHILE;
LEAVE populate;
END LOOP populate;
SELECT "Kedar Vaijanapurkar" AS "Developed by";
END$$

CREATE DEFINER=`admin`@`%` PROCEDURE `populate_fk` (`in_db` VARCHAR(50), `in_table` VARCHAR(50), `in_rows` INT, `in_debug` CHAR(1))  fk_load:BEGIN

select CONCAT("UPDATE ",TABLE_NAME," SET ",COLUMN_NAME,"=(SELECT ",REFERENCED_COLUMN_NAME," FROM ",REFERENCED_TABLE_SCHEMA,".",REFERENCED_TABLE_NAME," ORDER BY RAND() LIMIT 1);") into @query from information_schema.key_column_usage where TABLE_NAME=in_table AND TABLE_SCHEMA=in_db AND CONSTRAINT_NAME <> 'PRIMARY';
	IF in_debug='Y' THEN
		select @query;
	END IF;
if @query is null then
select "No referential information found." as Error;
LEAVE fk_load;
end if;

set  foreign_key_checks=0;
call populate(in_db,in_table,in_rows,'N');
PREPARE t_stmt FROM @query;
EXECUTE t_stmt;

set  foreign_key_checks=1;

END$$

--
-- Functions
--
CREATE DEFINER=`admin`@`%` FUNCTION `get_date` () RETURNS VARCHAR(10) CHARSET utf8mb4 RETURN DATE(FROM_UNIXTIME(RAND() * (1356892200 - 1325356200) + 1325356200))$$

CREATE DEFINER=`admin`@`%` FUNCTION `get_datetime` () RETURNS VARCHAR(30) CHARSET utf8mb4 RETURN FROM_UNIXTIME(ROUND(RAND() * (1356892200 - 1325356200)) + 1325356200)$$

CREATE DEFINER=`admin`@`%` FUNCTION `get_enum` (`col_type` VARCHAR(100)) RETURNS VARCHAR(100) CHARSET utf8mb4 RETURN if((@var:=ceil(rand()*10)) > (length(col_type)-length(replace(col_type,',',''))+1),(length(col_type)-length(replace(col_type,',',''))+1),@var)$$

CREATE DEFINER=`admin`@`%` FUNCTION `get_float` (`in_precision` INT, `in_scale` INT) RETURNS VARCHAR(100) CHARSET utf8mb4 RETURN round(rand()*pow(10,(in_precision-in_scale)),in_scale)$$

CREATE DEFINER=`admin`@`%` FUNCTION `get_int` () RETURNS INT(11) RETURN floor(rand()*10000000)$$

CREATE DEFINER=`admin`@`%` FUNCTION `get_string` (`in_strlen` INT) RETURNS VARCHAR(500) CHARSET utf8mb4 BEGIN
set @var:='';
IF (in_strlen>500) THEN SET in_strlen=500; END IF;
while(in_strlen>0) do
set @var:=concat(@var,IFNULL(ELT(1+FLOOR(RAND() * 53), 'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z',' ','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'),'Kedar'));
set in_strlen:=in_strlen-1;
end while;
RETURN @var;
END$$

CREATE DEFINER=`admin`@`%` FUNCTION `get_time` () RETURNS INT(11) RETURN TIME(FROM_UNIXTIME(RAND() * (1356892200 - 1325356200) + 1325356200))$$

CREATE DEFINER=`admin`@`%` FUNCTION `get_tinyint` () RETURNS INT(11) RETURN floor(rand()*100)$$

CREATE DEFINER=`admin`@`%` FUNCTION `get_varchar` (`in_length` VARCHAR(500)) RETURNS VARCHAR(500) CHARSET utf8mb4 RETURN SUBSTRING(MD5(RAND()) FROM 1 FOR in_length)$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `Customer`
--

CREATE TABLE `Customer` (
  `id` int(11) NOT NULL,
  `code` varchar(255) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `address` varchar(255) DEFAULT NULL,
  `contact` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `Customer`
--

INSERT INTO `Customer` (`id`, `code`, `name`, `address`, `contact`) VALUES
(5, '1', '1', '1', '1');

-- --------------------------------------------------------

--
-- Table structure for table `Invoice`
--

CREATE TABLE `Invoice` (
  `id` int(11) NOT NULL,
  `total_amount` int(11) UNSIGNED DEFAULT 0,
  `amount_tendered` int(11) UNSIGNED DEFAULT 0,
  `date_recorded` date NOT NULL DEFAULT current_timestamp(),
  `note` text DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `customer_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `Invoice`
--

INSERT INTO `Invoice` (`id`, `total_amount`, `amount_tendered`, `date_recorded`, `note`, `user_id`, `customer_id`) VALUES
(39, 9999, 0, '2022-02-05', NULL, 1, NULL),
(40, 15000, 20000, '2022-02-07', NULL, 1, NULL),
(41, 23000, 50000, '2022-02-07', NULL, 1, NULL),
(42, 24000, 50000, '2022-02-07', NULL, 1, NULL),
(43, 8000, 10000, '2022-02-07', NULL, 1, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `Product`
--

CREATE TABLE `Product` (
  `id` int(11) NOT NULL,
  `code` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `unit_in_stock` int(11) UNSIGNED NOT NULL DEFAULT 0,
  `disc_percentage` int(11) UNSIGNED NOT NULL DEFAULT 0,
  `unit_price` int(11) UNSIGNED NOT NULL DEFAULT 0,
  `capital_price` int(11) NOT NULL,
  `distributor_price` int(255) DEFAULT NULL,
  `re_order_level` varchar(255) DEFAULT NULL,
  `unit_id` int(11) DEFAULT NULL,
  `category_id` int(11) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `Product`
--

INSERT INTO `Product` (`id`, `code`, `name`, `unit_in_stock`, `disc_percentage`, `unit_price`, `capital_price`, `distributor_price`, `re_order_level`, `unit_id`, `category_id`, `user_id`) VALUES
(1, '8853301550017', 'Whiskas Tuna 85 gr', 10, 1, 80000, 0, NULL, '0', NULL, 6, 1),
(2, 'W4', 'Universal Persia(20Kg)', 0, 0, 0, 0, NULL, '0', NULL, 6, 1),
(3, 'c07', 'Colar07', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(4, 'WE210101', 'Mainan bulu ayam panjang acis1', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(5, 'RQ01', 'RC Queen 500 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(6, 'TI', 'Tablet Introducer', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(7, 'PC2', 'Pet Cage 083', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(8, '3182550799737', 'RC Skin Hair Ball 400 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(9, 'HDry', 'Hair Dry', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(10, '6948993725217', 'Sisir Petlot', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(11, '610376164249', 'Vitakraft Chicken(1kotak)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(12, '3182550787963', 'RC HEPATIC 2KG', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(13, '6941333416042', 'Catty Man Creamy Salmon 90 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(14, '680226249201', 'Cici Mackarel 400 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(15, 'I.C', 'ikan capnit30k', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(16, 'AR1', 'Araton Kitten 500 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(17, 'CT', 'Cici Tuna 500 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(18, 'CTTM', 'Catty Man Chiken & Oat (isi 5bh)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(19, 'S1', 'Susu  Milky Var', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(20, '7610376164232', 'Vitakraft Salmon(1kotak)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(21, 'WE210044', 'Tongkat Bulu AYam Panjang Acis2', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(22, '5404009517241', 'Healthy Persian Adult 1,5 kg', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(23, 'BD', 'Bowl Doble', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(24, '052742118000', 'Hairball Control Hills 2 kg', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(25, '680226249072', 'Cici Tuna 85 gr ( 1 box isi 12 )', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(26, 'W8', 'Universal Seafood(400g)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(27, 'H150', 'Hills 150 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(28, '3182550771252', 'RC GASTRO INTESTINAL 2KG', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(29, 'GX', 'Gusanex', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(30, '9555570900669', 'Bioion Pets Pounce 500 ml Ocean', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(31, 'KBK', 'Kalung Bel Karakter', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(32, 'Disp 1', 'Pet Dispenser', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(33, '680226249201', 'Cici Mackarel 400 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(34, 'PT15K', 'Mainan pancingan tikus', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(35, 'PZ', 'Pasir Zeolit', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(36, 'VO', 'Vet Otic', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(37, '680226249102', 'Cici Tuna Topping Katsuoboshi 85g (1 box isi 12)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(38, '680226249119', 'cici shirasu 85 g( isi 12)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(39, 'WK100', 'Pet Travel Bag', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(40, '18853301550045', 'Whiskas Tuna Junior 85g (1box isi 24)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(41, '3182550702614', 'RC Persian Adult(2Kg)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(42, '9555570900034', 'Deo Sanitizer', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(43, 'RCPKitt', 'RC Persian Kitten 500 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(44, '3182550771245', 'RC Gastro Intestinal(400g)', 100, 0, 0, 0, NULL, '0', 5, 6, 1),
(45, '680226249980', 'Cici Tuna 400 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(46, '8990895000037', 'Susu Ameri Pro 200 g', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(47, 'US-Z1718', 'Catty Man CHIKEN & Oat', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(48, 'UA-S01120100', 'Pet Cargo Pratiko', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(49, '3182550749473', 'RC Ped Growth 2 kg', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(50, '9555748901108', 'Pasir wangi kawan 20 kg lavender', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(51, 'T.t', 'True Touch', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(52, '9300605104747', 'Proplan Kitten 7 kg', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(53, '3182550702607', 'RC Persian Adult(400g)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(54, 'W11', 'Universal Tuna(1Kg)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(55, '8859160400234', 'Toro Chicken & Vegetable', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(56, '680226249126', 'Cici Tuna Topping Surimi (1 box isi 12)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(57, '899818391358813', 'Shampho more more medicinal 200 ml', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(58, '3182550725026', 'RC Ped. Weaning(400g)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(59, 'Kit10', 'Universal Kitten 10 kg', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(60, 'W5404009515780', 'Healthy pet 500 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(61, '8850292591739', 'shampo chic & cham polo sp 250 ml', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(62, '3182550906241', 'RC Gastro Kitten 400g', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(63, 'Mod', 'Bowl Modena', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(64, 'W1', 'Universal Kitten (20Kg)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(65, '680226249065', 'Cici Tuna Topping Surimi 85g', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(66, 'SBMilk1', 'Susu RC Babycat milk 100 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(67, 'RC P', 'RC Persian Adult 500 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(68, '8998183916114', 'shampo henpets medicinal 500ml', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(69, '6948993762113', 'Gunting kuku Petlot', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(70, 'W12', 'Universal Tuna(400g)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(71, 'whc12', 'Whiskas CHIKEN & INGRAVY 85 gr (1 BOX 12 BH)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(72, 'Gentik', 'Obat Kutu Gentik 1 ml', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(73, 'W15', 'Universal Prawn(1Kg)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(74, 'VIT4008239235206', 'Vitakraft Itik', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(75, '3182550770941', 'RC Maine Coon 400 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(76, 'TBab', 'Tempat BAB Lokal', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(77, '9555570903196', 'Bioion Pets Pounce 60 ml', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(78, 'A-B2', 'PET DRINKING BOTTLE 500ML', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(79, 'W20', 'Universal Persia 500 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(80, '4976555850567', 'Pampers Kucing', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(81, 'Erla', 'Erlamycetin salep mata', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(82, 'AC1', 'Mainan Ikan Capnip', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(83, 'USea', 'Universal Seafood(22Kg)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(84, '8859160400234', 'Toro Chicken and Vegetable', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(85, '9003579013410', 'RC Gastro Kitten 195 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(86, 'USea2', 'Universal Seafood(1Kg)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(87, '18853301550076', 'whiskas mackarel & Salmon 85gr (1 box 24)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(88, 'I.C', 'ikan capnit20k', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(89, '9003579309506', 'RC Gastro Intestinal 100 gr ( 1box 12 bh)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(90, 'whT12', 'whiskas Tuna jr 85 gr ( 1 box 12 bh)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(91, '0680226249164', 'Cici Tuna Topping Katsuoboshi 85g (1 box isi 24)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(92, 'M001', 'Kalung Harnez M001-M008', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(93, 'K.Bcow', 'Kalung bel biasa COW COW', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(94, 'Pro', 'Probiovar', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(95, '3182550759670', 'Sensitivty Control 400 g', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(96, 'Scab', 'Scabivar', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(97, 'R Ball', 'RC Skin n Hair Ball 1,5 kg', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(98, '8853301550024', 'Whiskas Tuna & White Fish Adult 85g', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(99, 'W3', 'Universal Kitten(1Kg)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(100, 'OMed', 'Obat Kutu Spray Medipet 30 ml', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(101, '8853301550062', 'Whiskas chiken & ingravy 85 gr ( 1 BH)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(102, '8850172400045', 'Drontal Plus', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(103, '680226249058', 'cici shirasu 85 g', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(104, 'whsmjr', 'whiskas mackarel jr 85 gr (12bh)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(105, 'RAd1', 'RC Adult 2 kg', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(106, 'Urcare', 'RC Urinary care 400 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(107, '8853301550017', 'Whiskas Tuna Adult 85 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(108, 'Dem', 'Demodis', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(109, '9555748901047', 'Pasir wangi kawan 10 ltr lemon', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(110, '4008239235206', 'Vitakraft Itik(1kotak)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(111, '7610376164249', 'Vitakraft Chicken (1 kotak )', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(112, 'cttm', 'Catty Man Tuna & Oat ( isi 5 bh)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(113, 'TAKe1', 'Tempat BAB Kecil', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(114, '9555570900584', 'Bioion Pets Pounce 500 ml Floral', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(115, '3182550767262', 'RC Aroma Exigent', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(116, 'SF1', 'Shampo Fungizol', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(117, 'BW2', 'Bioion Wet Wipes', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(118, 'S2', 'Susu Lactozim 25 g', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(119, 'k.b', 'least colar', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(120, 'kab', 'Kalung Anak Kucing', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(121, '3182550759670', 'RC Sensi Control', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(122, 'SK 9500', 'Sisir Kandila NG9500-2', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(123, 'SBab', 'SKOP BAB', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(124, 'I.C', 'ikan capnit25k', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(125, 'KD3', 'Kandang 014', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(126, '052742567006', 'Urgen Care a/d', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(127, '4008429009389', 'RC Convallescence Support 50 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(128, '052742462806', 'Digesty Care i/d', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(129, 'HEA1', 'Healthy  500 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(130, 'KH', 'Kalung Harnez', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(131, 'PDream', 'Pet Dream ( Pasir organik) 15 kg', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(132, 'CKit', 'Cici Kitten 500 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(133, '1212333741053', 'Shampo Cevlon 60 ml  lemongrass ekstract', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(134, 'KERI1', 'Keranjang Rio Kecil', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(135, 'TBesar', 'Tempat BAB Besar', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(136, 'kp', 'RC Kitten Persia 150gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(137, '9555748901016', 'Pasir wangi kawan 5 ltr apple', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(138, '3182550721721', 'RC Hair & Skin(400g)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(139, '680226249515', 'cici tuna Taurine kitten 85gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(140, '123', 'dsa', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(141, 'SM', 'Sikat Mandi', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(142, '4433512', 'Cat Litter Box Rec', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(143, '4710716642024', 'Link Roller', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(144, 'W9', 'Universal Tuna(22Kg)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(145, '9555748901337', 'Pasir wangi kawan 20 kg coffee', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(146, '9003579010044', 'RC Urinary s/o 85 gr ( 1box 12 bh)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(147, '3182550906258', 'RC GASTRO KITTEN 2KG', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(148, 'ICat 9', 'Inspiration Cat 9 kg', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(149, '3182550721226', 'RC Kitten Persian 4 kg', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(150, 'US-Z178', 'Catty Man SALMON & Oat', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(151, '3182550759687', 'RC Sensi Control 1,5 kg', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(152, 'S1', 'Susu  Milky Var', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(153, '3182550799621', 'RC Neut Satiety 400 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(154, 'RC Wea2', 'RC Ped Weaning 2 kg', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(155, 'R9003579305461', 'RC Urinari s/o 100 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(156, 'bba', 'Bola Bulu Ayam', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(157, 'SK98302', 'Sisir Kandila M98302S-2', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(158, '8853301550048', 'Whiskas Tuna Junior 85g', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(159, '9003579011522', 'RC Skin & Coat 85 gr ( 1 box 12 bh)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(160, '8853301550055', 'Whiskas Ocean Fish 85g', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(161, 'spfj', 'Shampo profesional jamur 40 ml', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(162, '5404009515780', 'Healthy pet 7,5 kg', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(163, '3182550721738', 'RC Hair & Skin(2Kg)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(164, '680226249546', 'cici tuna goatmilk kitten 85 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(165, 'W8853301550079', 'Whiskas Mackerel Salmon Adult 85g (1box isi 24)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(166, 'PG1', 'PET Carier Air Box', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(167, 'KD2', 'Kandang 013', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(168, '052742004969', 'Hills Kitten 500 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(169, 'POr', 'Pasir Organik 1,5 kg', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(170, 'ctmbo', 'Catty Man BEEF & Oat (isi 5bh)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(171, '0680226249140', 'Cici Tuna Toping Salmon  (1 b0x isi 24)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(172, 's4000', 'Simba', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(173, 'CB', 'Colar Buster  7,5', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(174, 'PW', 'pasir wangi kawan 10L  ROSE', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(175, 'KB.A', 'kalung bel biasa Acis', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(176, '0680226249133', 'Cici Tuna 85 gr ( 1 box isi 24)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(177, 'Pro2', 'Proplan adult 500 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(178, '8859160400241', 'toro chiken & katsubosi', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(179, 'L.k', 'lonceng boneka', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(180, 'W8853301550024', 'Whiskas Tuna & White Fish Adult 85g (1box isi 24)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(181, 'RPW', 'RC Ped Weaning 100 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(182, '9555748901290', 'Pasir wangi 10 ltr rose', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(183, 'US-Z1719', 'Catty Man BEEF & Oat', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(184, '8850292591722', 'shampo chic & cham kenz flower 250 ml', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(185, 'P077', 'Pet Cage 077', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(186, '9555748901030', 'Pasir wangi kawan 5 ltr baby powder', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(187, 'MC1', 'Momo Cat 20 kg', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(188, 'eu1', 'Euricen 6', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(189, 'SC1,5', 'RC Skin & Coat 1,5 kg', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(190, '8853301550079', 'Whiskas Mackarel dan Salmon Adult 85 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(191, 'UTun', 'Universal Tuna 500 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(192, 'MBA Pj', 'Mainan Tongkat Bulu Ayam Pjg', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(193, 'SC3', 'Shampho Cleon Avocado 250 ml', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(194, '3182550711159', 'RC Urinary 1,5 kg', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(195, 'FO1', 'Fish Oil 50', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(196, 'PZ', 'Pasir Zeolit 2 kg', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(197, 'bbj', 'baju kucing', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(198, 'W13', 'Universal Prawn(8Kg)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(199, '0680226249171', 'cici shirasu 85 gr( 1 box 24)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(200, '0680226249157', 'Cici Tuna Topping Chicken 85g (1 box isi 24)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(201, '3182550721219', 'RC Persian Kitten(2Kg)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(202, '31825507709416;yl.', 'RC Kitten Maine Coon', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(203, '680226249096', 'Cici Tuna Topping Chicken 85g (1 box isi 12)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(204, 'SFung', 'Shampoo Fungizol', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(205, '9992018020167', 'Susu Champion Breed', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(206, '9003579307717', 'RC Recovery', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(207, '1212333741059', 'Shampho Cevlon 60 ml Pepaya ekstract', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(208, 'P20L', 'Pasir wangi 20 kg lemon', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(209, 'EBO', 'Kanebo', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(210, 'PO15', 'Pasir organik 15 kg', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(211, 'RB', 'keranjang rio besar', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(212, 'I.C', 'ikan capnit35k', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(213, 'OVAL TC01', 'PET BED Oval', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(214, 'P10', 'Universal Persia 10 kg', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(215, '8859160400241', 'Toro Chicken & Katsubushi', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(216, '680226249027', 'Cici Tuna Topping Salmon', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(217, '680226249041', 'Cici Tuna Topping Katsuoboshi 85g', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(218, '3182550771320', 'RC Gastro Fiber 400 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(219, 'CT012', 'Cat Tree CT012', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(220, '9003579308943', 'RC Kitten 36 85 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(221, '8859160400296', 'Toro Tuna Plus Fiber ( 1 bks 5 bh)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(222, '8857123974723', 'cici salmon 500gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(223, '8859160400258', 'Toro Tuna Plus Fiber', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(224, 'UA13cc', 'Kandang 13 cc', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(225, '9300605104761', 'Proplan Salmon Adult 7 kg', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(226, '3182550704533', 'RC Persian Adult 4 kg', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(227, 'Gentik 2', 'Obat Kutu Gentik 2 ml', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(228, 'GK Kan', 'Gunting Kuku Kandila 624-2', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(229, 'Hapel 01', 'Harnez Pelangi', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(230, 'FO2', 'Minyak Ikan 100', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(231, '8859160400265', 'Toro Tuna & Katsubushi', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(232, '8997215690015', 'Susu Growssy 20 g', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(233, '9555748901092', 'Pasir wangi kawan 20 kg apple', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(234, 'mb1', 'Mainan Bola Kerincing Bulu Ayam', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(235, '8998183915100', 'shampo pt_pet mild 15 ml', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(236, '18853301550120', 'Whiskas Mackerel Junior 85g (1box isi 24)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(237, '6941333416035', 'Catty Man Creamy Bonito 90 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(238, '3182550711043', 'RC Urinary S/O(400g)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(239, 'm.b', 'mainan bola tikus ', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(240, 'DM1', 'Dispenser mangkok makanan', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(241, 'HB1', 'Herbavit', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(242, 'UPer', 'Universal Persia 1 kg', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(243, '8991006', 'Im Organik KBM 7,5 kg', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(244, '6941333416059', 'Catty Man Creamy Chicken', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(245, '3182550799683', 'Adult 2 kg', 99, 0, 0, 5000, NULL, '0', 5, 9, 1),
(246, 'smb', 'simba', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(247, 'RB', 'Rol Bulu', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(248, 'NPG', 'Nutri Plus Gell', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(249, 'tk', 'tas kucing', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(250, 'VIT7610376164232', 'Vitakraft Salmon', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(251, 'RG200', 'RC Gastro Kitten 200 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(252, 'RC G 2', 'RC Ped Growth 2 kg', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(253, 'Imo2', 'Im Organik 250 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(254, 'SC1', 'Shampoo Cleon Chery 250 ml', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(255, '8859160400272', 'Toro Chicken and Vegetable ( 1 bks isi 5 buah)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(256, '3182550711159', 'RC Urinary S/O(1,5Kg)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(257, '3182550702447', 'RC Kitten 36 4 kg', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(258, 'MCat', 'Momo cat 1 kg', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(259, 'MBA', 'Mainan Tongkat Bulu Ayam/Tikus Pendek', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(260, '3182550702423', 'RC Kitten 36(2Kg)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(261, 'PTS-2521', 'Sisir  Petlot PTS-2521', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(262, '1212333741055', 'Shampo Cevlon 60 ml Alovera ekstract', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(263, '18853301550038', 'Whiskas Mackarel Adult 85 gr ( 1 box 24)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(264, '9003579308929', 'RC Care Intense Beauty 85 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(265, 'kb.bo', 'kalung bel biasa boo_bo15k', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(266, 'K25', 'Kalung jalin boneka 25 K', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(267, 'DT', 'Dot 75 ml', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(268, 'Round Bed TC 02', 'PET BED', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(269, 'US-Z178', 'Catty Man SALMON & Oat (isi 5bh)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(270, '3182550799744', 'RC Skin Hairball 1,5 kg', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(271, '9310022807619', 'Whiskas OF 400 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(272, 'NHS73', 'Gunting kuku NHS 73', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(273, 'Grape1', 'shamphoo Cleon Grape', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(274, 'Im2', 'Immunol 2 ml', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(275, 'US-Z1721', 'Catty Man Tuna & Oat', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(276, 'Tapel01', 'Tali Pelangi', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(277, 'SK 420', 'Sisir Kandila 420-2', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(278, '5404009513939', 'Healthy Pet(1,5Kg)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(279, '9555748901061', 'Pasir wangi kawan 10 ltr lavender', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(280, 'BKitty', 'Bowl Hello kitty', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(281, '9555748901009', 'Pasir wangi 5 ltr lemon', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(282, '9555748901054', 'Pasir wangi kawan 10 ltr apple', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(283, 'ICat 1000', 'Inspiration Cat 1 kg', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(284, '8853301550031', 'Whiskas Mackarel Adult 85 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(285, '8853301550123', 'Whiskas Mackerel Junior 85g ', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(286, 'SR1', 'Shampo Rosemary', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(287, 'wh12', 'whiskas mackarel & salmon 85 gr ( 1bok 12 bh)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(288, '9555748901023', 'Pasir wangi kawan 5 ltr lavender', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(289, 'P Acis1', 'Pasir Acis 20 kg', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(290, '3182550725156', 'RC Ped. Growth(400g)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(291, '8850477001664', 'Meo Kitten 1,1 kg', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(292, '4712896761700', 'Dot 50 ml', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(293, '8212342570796', 'shampo Mild 200 ml Medicated', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(294, '18853301550069', 'WHISKAS CHIKEN & INGRAVY 85 gr (1 BOX24 BH)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(295, '8998183913557', 'Shampho more more Deodoring 200 ml', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(296, 'W2', 'Universal Kitten (500gr)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(297, 'KD1', 'Kandang 012', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(298, 'SC2', 'Shampho Cleon lemon 250 ml', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(299, '9003579311660', 'RC Babycat 185 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(300, '9310022807619', 'Whiskas Tuna 400 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(301, '680226249768', 'Cici Mackarel GF 85 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(302, '9003579311202', 'RC Ped Growth 100 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(303, '6043100', 'KandangCC304', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(304, 'R9003579011522', 'RC Skin & Coat 85 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(305, 'c06', 'Colar06', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(306, '3182550721202', 'RC Persian Kitten(400g)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(307, '8850172400182', 'Advocate S', 14, 0, 0, 0, NULL, '0', NULL, 6, 4),
(308, '8859160400289', 'Toro Chicken and Katsuobushi ( 1 box isi 5 bks)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(309, '8853301550079', 'Whiskas Mackerel & Salmon Adult 85g', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(310, 'R9003579309506', 'RC Gastro Intestinal 100 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(311, '071860314491', 'Sure Growth', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(312, 'KBig', 'Kalung lonceng besar', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(313, 'PHPJ', 'Parfum HPJ 60 ml', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(314, 'MK', 'Meo Kitten 500 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(315, 'sc6', 'shampo cleon milk 250 ml', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(316, '8887677600793', 'Pasir Sumo 10 ltr cofee', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(317, 'UPR', 'Universal Praw 500 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(318, '8850477002449', 'Meo Kitten 7 kg', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(319, '3182550702157', 'RC FIT32 400 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(320, 'W16', 'Universal Prawn(400g)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(321, 'W18', 'Imperial Paw (15kg)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(322, 'V7610376164249', 'Vitakraft chicken', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(323, '8850292590060', 'Shampo Bearing 365 ml', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(324, '6802262494160', 'Savvy Tuna Sardine 400 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(325, '9003579310922', 'RC Ped Growth 100 gr ( 1box 12 bh)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(326, '680226249010', 'Cici Tuna 85 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(327, '5404009515896', 'Healthy Pet(400g)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(328, '3182550842907', 'RC Urinary Care 400 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(329, '9555570900058', 'Bioion Pets Pounce 500 ml original', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(330, '9003579308745', 'RC Kitten 36 85 gr ( 1 box 12 bh)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(331, 'Pro 1', 'Proplan Kitten 500 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(332, '9003579308936', 'RC Instinctive 85 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(333, '1212333741051', 'Shampo Cevlon 60 ml Lime ekstract', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(334, 'PCi1', 'Pasir Cici 10 ltr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(335, '9003579311653', 'RC Ped Weaning 195 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(336, '9555544200085', 'Pro Diet', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(337, 'RC 1', 'RC Kitten 36 500 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(338, '4007221049951', 'Drontal Cat', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(339, 'Ar2', 'Araton 7,5 kg', 99, 0, 0, 0, 1000, '0', 5, 6, 1),
(340, 'BS1', 'Bowl Single', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(341, 'W17', 'Imperial Paw(500g)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(342, 'im3', 'im organik 500g', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(343, '3182550899321', 'RC Skin & Coat 400 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(344, 'W6', 'Universal Persia(500g)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(345, 'SI 457', 'Sisir Kawat Sweet 457', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(346, '8850292420114', 'Bedak Bearing', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(347, '816012014143', 'Im Organik 1,8 kg', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(348, '3182550898829', 'RC Hypoallergenic 400 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(349, 'MCat2', 'Momo Cat 500 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(350, 'C05', 'Colar05', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(351, 'ICat 500', 'Inspiration Cat 500 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(352, 'Imo', 'Im Organik 300 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(353, 'USea', 'Universal Seafood 500 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(354, 'W8853301550055', 'Whiskas Ocean Fish Adult 85g (1box isi 24)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(355, 'K 010', 'Kandang 010 M', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(356, 'F136', 'Kandang Tingkat F136', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(357, 'W14', 'Universal Prawn(20Kg)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(358, 'Decom', 'Decompovar', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(359, 'SC4', 'Shampo Cleon Grape 200 ml', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(360, '8212342570741', 'Shampo Mild 200 ml Clean n Fresh', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(361, 'RPed150', 'RC Ped Weaning 150 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(362, 'WM', 'Whiskas Mackarel Adult 85 gr ( 1 box 12 bh)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(363, 'SKan', 'Sisir Kandila NG9632 D2', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(364, '3182550906241', 'Gastro Kitten 400 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(365, '8998183916091', 'shampo henpets deodorizing 500ml', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(366, '0680226249188', 'Cici Tuna Topping Surimi', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(367, '6941333416066', 'Catty Man Creamy Milk 90 gr', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(368, '3182550707312', 'RC Mother & Babycat(2Kg)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(369, '9300605104990', 'Proplan Kitten 2,5 kg', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(370, '3182550702379', 'RC Kitten 36(400g)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(371, '680226249034', 'Cici Tuna Topping Chicken 85g', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(372, 'Tuntop', 'Cici Tuna Topping Tuna Asap (1 box isi 24)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(373, 'B.K00', 'bola kerincing', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(374, '3182550707305', 'RC Mother & Babycat(400g)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(375, 'SK Hua', 'Sisir Kutu  Huanfa', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(376, '8998183916015', 'shampo henpets flea & tick 500ml', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(377, 's.pf', 'shampo propessional formula flea & tick 40ml', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(378, '1212333741057', 'Shampo cevlon 60 ml avocado ekstract', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(379, 'PW1', 'Pasir wangi 2 kg', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(380, 'K.B', 'kalung boneka 20k', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(381, 'W5', 'Universal Persia(1Kg)', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(382, '3182550710862', 'Susu RC Babycat milk', 0, 0, 0, 0, NULL, '0', NULL, NULL, NULL),
(385, 'x', 'x', 0, 1, 1, 6000, 1, '1', 5, 6, 1);

-- --------------------------------------------------------

--
-- Table structure for table `Product Category`
--

CREATE TABLE `Product Category` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL DEFAULT '-'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `Product Category`
--

INSERT INTO `Product Category` (`id`, `name`) VALUES
(6, 'Kue Bakwan'),
(7, 'Kue Putu'),
(8, 'Kue Molen'),
(9, 'Kue Bau');

-- --------------------------------------------------------

--
-- Table structure for table `Product Unit`
--

CREATE TABLE `Product Unit` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL DEFAULT '-'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `Product Unit`
--

INSERT INTO `Product Unit` (`id`, `name`) VALUES
(5, 'Kg');

-- --------------------------------------------------------

--
-- Table structure for table `Purchase Order`
--

CREATE TABLE `Purchase Order` (
  `id` int(11) NOT NULL,
  `qty` int(11) UNSIGNED NOT NULL,
  `sub_total` int(11) UNSIGNED NOT NULL,
  `order_date` date NOT NULL DEFAULT current_timestamp(),
  `unit_price` int(11) UNSIGNED NOT NULL DEFAULT 0,
  `product_id` int(11) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `supplier_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `Purchase Order`
--

INSERT INTO `Purchase Order` (`id`, `qty`, `sub_total`, `order_date`, `unit_price`, `product_id`, `user_id`, `supplier_id`) VALUES
(5, 1, 1, '2022-02-02', 1, 13, 1, 2);

-- --------------------------------------------------------

--
-- Table structure for table `Receive Product`
--

CREATE TABLE `Receive Product` (
  `id` int(11) NOT NULL,
  `qty` int(11) UNSIGNED NOT NULL,
  `unit_price` int(11) UNSIGNED NOT NULL,
  `sub_total` int(11) UNSIGNED NOT NULL,
  `additional_expenses` int(11) NOT NULL DEFAULT 0,
  `received_date` date NOT NULL DEFAULT current_timestamp(),
  `expired_date` date DEFAULT NULL,
  `product_id` int(11) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `supplier_id` int(11) DEFAULT NULL,
  `unit_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `Receive Product`
--

INSERT INTO `Receive Product` (`id`, `qty`, `unit_price`, `sub_total`, `additional_expenses`, `received_date`, `expired_date`, `product_id`, `user_id`, `supplier_id`, `unit_id`) VALUES
(10, 1, 1, 1, 0, '2022-01-22', '2022-02-04', 12, 1, 2, NULL),
(11, 20, 1, 1, 0, '2022-02-02', '2022-02-04', 197, 1, 2, NULL),
(12, 1, 1, 1, 0, '2022-02-02', '2022-02-04', 1, 1, 2, NULL),
(13, 1, 1, 1, 0, '2022-02-02', '2022-02-04', 1, 1, 2, NULL),
(14, 1, 1, 1, 0, '2022-02-02', '2022-02-04', 1, 1, 2, NULL),
(15, 1, 1, 1, 0, '2022-02-02', '2022-02-04', 1, 1, 2, NULL),
(16, 50, 1, 1, 0, '2022-02-02', '2022-02-04', 1, 1, 2, NULL),
(17, 50, 1, 1, 0, '2022-02-02', '2022-02-04', 1, 1, 2, NULL),
(18, 20, 2000, 5000, 0, '2022-02-02', '2022-02-04', 245, 1, 2, NULL),
(19, 20, 2000, 289999, 0, '2022-02-02', '2022-02-04', 245, 1, 2, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `Revoked Tokens`
--

CREATE TABLE `Revoked Tokens` (
  `id` int(11) NOT NULL,
  `token` text DEFAULT NULL,
  `signed_out` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `Revoked Tokens`
--

INSERT INTO `Revoked Tokens` (`id`, `token`, `signed_out`) VALUES
(24, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MSwidXNlcm5hbWUiOiJhZG1pbiIsInBhc3N3b3JkIjoiJDJhJDEwJGZjQW4uOEZ0VGk3NnZUWkE3YjFFRC5TN2FwNTJlNW14NlFELzRLOGpJSlp3T3hiZUo1L042IiwiZnVsbG5hbWUiOm51bGwsInJvbGUiOiJhZG1pbiIsImNvbnRhY3QiOm51bGwsImlhdCI6MTY0NDIyMzc0MSwiZXhwIjoxNjQ0MzEwMTQxfQ.hvHzeecAOZSYaDYOpaE2pRUTPnn1D_QrGPRdl4yKcE4', 0),
(25, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MSwidXNlcm5hbWUiOiJhZG1pbiIsInBhc3N3b3JkIjoiJDJhJDEwJGZjQW4uOEZ0VGk3NnZUWkE3YjFFRC5TN2FwNTJlNW14NlFELzRLOGpJSlp3T3hiZUo1L042IiwiZnVsbG5hbWUiOm51bGwsInJvbGUiOiJhZG1pbiIsImNvbnRhY3QiOm51bGwsImlhdCI6MTY0NDg4NjU4MiwiZXhwIjoxNjQ0OTcyOTgyfQ.IUdCt9YSmVXrXUC99dTtXrZeFHYaDqCMI_vh3yAFSvQ', 1),
(26, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MSwidXNlcm5hbWUiOiJhZG1pbiIsInBhc3N3b3JkIjoiJDJhJDEwJGZjQW4uOEZ0VGk3NnZUWkE3YjFFRC5TN2FwNTJlNW14NlFELzRLOGpJSlp3T3hiZUo1L042IiwiZnVsbG5hbWUiOm51bGwsInJvbGUiOiJhZG1pbiIsImNvbnRhY3QiOm51bGwsImlhdCI6MTY0NDg5NTI5OSwiZXhwIjoxNjQ0OTgxNjk5fQ.esS3jsfBw5-JB_xoYPdTsZpV_qoUp_vTn2a5r8J4JuI', 0);

-- --------------------------------------------------------

--
-- Table structure for table `Sales`
--

CREATE TABLE `Sales` (
  `id` int(11) NOT NULL,
  `qty` int(11) UNSIGNED NOT NULL DEFAULT 0,
  `unit_price` int(11) UNSIGNED NOT NULL DEFAULT 0,
  `sub_total` int(11) UNSIGNED NOT NULL DEFAULT 0,
  `invoice_id` int(11) DEFAULT NULL,
  `product_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `Sales`
--

INSERT INTO `Sales` (`id`, `qty`, `unit_price`, `sub_total`, `invoice_id`, `product_id`) VALUES
(58, 2, 5000, 10000, 39, 245),
(60, 3, 2000, 6000, 40, 245),
(61, 3, 3000, 9000, 40, 307),
(62, 6, 2000, 12000, 41, 245),
(63, 2, 3000, 6000, 41, 307),
(64, 1, 5000, 5000, 41, 12),
(65, 3, 3000, 9000, 42, 307),
(66, 1, 5000, 5000, 42, 16),
(67, 1, 10000, 10000, 42, 385),
(68, 1, 2000, 2000, 43, 245),
(69, 2, 3000, 6000, 43, 307);

-- --------------------------------------------------------

--
-- Table structure for table `Supplier`
--

CREATE TABLE `Supplier` (
  `id` int(11) NOT NULL,
  `code` varchar(255) DEFAULT NULL,
  `name` varchar(255) NOT NULL,
  `email` varchar(255) DEFAULT NULL,
  `address` varchar(255) DEFAULT NULL,
  `contact` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `Supplier`
--

INSERT INTO `Supplier` (`id`, `code`, `name`, `email`, `address`, `contact`) VALUES
(2, '1', '1', '1', '1', '1');

-- --------------------------------------------------------

--
-- Table structure for table `User`
--

CREATE TABLE `User` (
  `id` int(11) NOT NULL,
  `username` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `fullname` varchar(255) DEFAULT NULL,
  `role` varchar(255) NOT NULL,
  `contact` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `User`
--

INSERT INTO `User` (`id`, `username`, `password`, `fullname`, `role`, `contact`) VALUES
(1, 'admin', '$2a$10$fcAn.8FtTi76vTZA7b1ED.S7ap52e5mx6QD/4K8jIJZwOxbeJ5/N6', NULL, 'admin', NULL),
(3, 'ihsankl', '$2a$10$7oe4qsOpLuEymJ6CIbB8M.qlCuPpB9SO2ds8UUMWRrDXvp/SMNqyW', NULL, 'admin', NULL),
(4, 'admin2', '$2a$10$qDn1kNBn35GG7TnQ9eyE7eZNmZ/htlwKK6vUYZFS4CuRbKCixPbGC', NULL, 'admin', NULL);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `Customer`
--
ALTER TABLE `Customer`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `Invoice`
--
ALTER TABLE `Invoice`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `Product`
--
ALTER TABLE `Product`
  ADD PRIMARY KEY (`id`),
  ADD KEY `category` (`category_id`),
  ADD KEY `user` (`user_id`),
  ADD KEY `unit` (`unit_id`);

--
-- Indexes for table `Product Category`
--
ALTER TABLE `Product Category`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `Product Unit`
--
ALTER TABLE `Product Unit`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `Purchase Order`
--
ALTER TABLE `Purchase Order`
  ADD PRIMARY KEY (`id`),
  ADD KEY `product_id` (`product_id`),
  ADD KEY `supplier_id` (`supplier_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `Receive Product`
--
ALTER TABLE `Receive Product`
  ADD PRIMARY KEY (`id`),
  ADD KEY `product_id` (`product_id`),
  ADD KEY `supplier_id` (`supplier_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `unit_id` (`unit_id`);

--
-- Indexes for table `Revoked Tokens`
--
ALTER TABLE `Revoked Tokens`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `Sales`
--
ALTER TABLE `Sales`
  ADD PRIMARY KEY (`id`),
  ADD KEY `invoice_id` (`invoice_id`),
  ADD KEY `product_id` (`product_id`);

--
-- Indexes for table `Supplier`
--
ALTER TABLE `Supplier`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `User`
--
ALTER TABLE `User`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `Customer`
--
ALTER TABLE `Customer`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `Invoice`
--
ALTER TABLE `Invoice`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=44;

--
-- AUTO_INCREMENT for table `Product`
--
ALTER TABLE `Product`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=386;

--
-- AUTO_INCREMENT for table `Product Category`
--
ALTER TABLE `Product Category`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `Product Unit`
--
ALTER TABLE `Product Unit`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `Purchase Order`
--
ALTER TABLE `Purchase Order`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `Receive Product`
--
ALTER TABLE `Receive Product`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=20;

--
-- AUTO_INCREMENT for table `Revoked Tokens`
--
ALTER TABLE `Revoked Tokens`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=27;

--
-- AUTO_INCREMENT for table `Sales`
--
ALTER TABLE `Sales`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=70;

--
-- AUTO_INCREMENT for table `Supplier`
--
ALTER TABLE `Supplier`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `User`
--
ALTER TABLE `User`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `Invoice`
--
ALTER TABLE `Invoice`
  ADD CONSTRAINT `Invoice_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `User` (`id`);

--
-- Constraints for table `Product`
--
ALTER TABLE `Product`
  ADD CONSTRAINT `category` FOREIGN KEY (`category_id`) REFERENCES `Product Category` (`id`),
  ADD CONSTRAINT `unit` FOREIGN KEY (`unit_id`) REFERENCES `Product Unit` (`id`),
  ADD CONSTRAINT `user` FOREIGN KEY (`user_id`) REFERENCES `User` (`id`);

--
-- Constraints for table `Purchase Order`
--
ALTER TABLE `Purchase Order`
  ADD CONSTRAINT `Purchase Order_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `Product` (`id`),
  ADD CONSTRAINT `Purchase Order_ibfk_2` FOREIGN KEY (`supplier_id`) REFERENCES `Supplier` (`id`),
  ADD CONSTRAINT `Purchase Order_ibfk_3` FOREIGN KEY (`user_id`) REFERENCES `User` (`id`);

--
-- Constraints for table `Receive Product`
--
ALTER TABLE `Receive Product`
  ADD CONSTRAINT `Receive Product_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `Product` (`id`),
  ADD CONSTRAINT `Receive Product_ibfk_2` FOREIGN KEY (`supplier_id`) REFERENCES `Supplier` (`id`),
  ADD CONSTRAINT `Receive Product_ibfk_3` FOREIGN KEY (`user_id`) REFERENCES `User` (`id`),
  ADD CONSTRAINT `Receive Product_ibfk_4` FOREIGN KEY (`unit_id`) REFERENCES `Product Unit` (`id`);

--
-- Constraints for table `Sales`
--
ALTER TABLE `Sales`
  ADD CONSTRAINT `Sales_ibfk_1` FOREIGN KEY (`invoice_id`) REFERENCES `Invoice` (`id`),
  ADD CONSTRAINT `Sales_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `Product` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
