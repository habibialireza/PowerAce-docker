CREATE DATABASE IF NOT EXISTS `iip-web-0002_definitions`;

USE `iip-web-0002_definitions`;

CREATE TABLE IF NOT EXISTS `tbl_demands` (
    `ID` INT NOT NULL,
    `name` VARCHAR(255) NOT NULL,
    PRIMARY KEY (`ID`)
);

CREATE TABLE IF NOT EXISTS `tbl_scenarios` (
    `scenario_ID` INT NOT NULL,
    `name` VARCHAR(255) NOT NULL,
    PRIMARY KEY (`scenario_ID`)
);

INSERT INTO `tbl_demands` (`ID`, `name`) VALUES
    (1, 'electricity')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

INSERT INTO `tbl_scenarios` (`scenario_ID`, `name`) VALUES
    (1, 'ERAA2025'),
    (2, 'ENTSO-E historical'),
    (3, 'TYNDP 2024 National Trends'),
    (4, 'ICE CO2 Future')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);
