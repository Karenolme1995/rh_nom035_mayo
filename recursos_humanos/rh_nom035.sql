/*
SQLyog Community v13.1.6 (64 bit)
MySQL - 8.0.41-0ubuntu0.24.04.1 : Database - aomproyectosbase
*********************************************************************
*/

/*!40101 SET NAMES utf8 */;

/*!40101 SET SQL_MODE=''*/;

/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
CREATE DATABASE /*!32312 IF NOT EXISTS*/`aomproyectosbase` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;

USE `aomproyectosbase`;

/*Table structure for table `answers` */

DROP TABLE IF EXISTS `answers`;

CREATE TABLE `answers` (
  `id` int NOT NULL AUTO_INCREMENT,
  `submission_id` int NOT NULL,
  `question_id` int NOT NULL,
  `option_id` int DEFAULT NULL,
  `answer_text` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_ans_sub` (`submission_id`),
  KEY `idx_ans_q` (`question_id`),
  KEY `fk_ans_option` (`option_id`),
  CONSTRAINT `fk_ans_option` FOREIGN KEY (`option_id`) REFERENCES `question_options` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ans_question` FOREIGN KEY (`question_id`) REFERENCES `questions` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ans_sub` FOREIGN KEY (`submission_id`) REFERENCES `submissions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

/*Data for the table `answers` */

insert  into `answers`(`id`,`submission_id`,`question_id`,`option_id`,`answer_text`,`created_at`,`updated_at`) values 
(15,1,1,1,NULL,'2026-02-25 10:25:26','2026-02-25 10:25:26'),
(16,1,2,NULL,'kiiuiiiiiiiiiiiiiiiiii','2026-02-25 10:25:26','2026-02-25 10:25:26');

/*Table structure for table `areas` */

DROP TABLE IF EXISTS `areas`;

CREATE TABLE `areas` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `active` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_areas_name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=45 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

/*Data for the table `areas` */

insert  into `areas`(`id`,`name`,`active`) values 
(1,'AGUASCALIENTES',1),
(2,'ALMACEN DE MATERIA PRIMA\r\n',1),
(3,'ALMACEN DE PRODUCTO TERMINADO\r\n',1),
(4,'ALMACEN DE REFACCIONES Y SUMINISTROS',1),
(5,'CALIDAD NAVE II',1),
(6,'CD. JUAREZ',1),
(7,'CHIHUAHUA',1),
(8,'CIUDAD DE MEXICO',1),
(9,'COMPRAS',1),
(10,'CONTRALORIA',1),
(11,'COORDINACION ISO 9000 Y 14000',1),
(12,'CREDITO Y COBRANZA',1),
(13,'DIRECCION DE OPERACIONES',1),
(14,'DIRECCION GENERAL',1),
(15,'DIRECCION JURIDICA',1),
(16,'EXTRUSIÓN',1),
(17,'FORMULACION',1),
(18,'GERENCIA ADMINISTRATIVA',1),
(19,'GERENCIA DE CONTABILIDAD',1),
(20,'GERENCIA DE CONTROL DE CALIDAD',1),
(21,'GERENCIA DE DESARROLLO',1),
(22,'GERENCIA DE OPERACIONES',1),
(23,'GERENCIA DE PLANTA',1),
(24,'GERENCIA DE PRODUCCION',1),
(25,'GERENCIA DE RECURSOS HUMANOS',1),
(26,'GERENCIA TI',1),
(27,'GUADALAJARA',1),
(28,'INGENIERIA Y MANTENIMIENTO',1),
(29,'LOGISTICA',1),
(30,'MEJORA CONTINUA',1),
(31,'MERIDA',1),
(32,'MEXICALI',1),
(33,'MEZCLADORA ROMBOIDAL',1),
(34,'MEZCLADORAS DE ALTA VELOCIDAD',1),
(35,'MOLINOS',1),
(36,'MOLINOS NAVE II',1),
(37,'MONTERREY',1),
(38,'POLVOS FINOS',1),
(39,'PUEBLA',1),
(40,'QUERETARO',1),
(41,'SAN LUIS POTOSI',1),
(42,'SEGURIDAD E HIGIENE',1),
(43,'TAMAULIPAS',1),
(44,'TORREON',1);

/*Table structure for table `cache` */

DROP TABLE IF EXISTS `cache`;

CREATE TABLE `cache` (
  `key` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `value` mediumtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `expiration` int NOT NULL,
  PRIMARY KEY (`key`),
  KEY `cache_expiration_index` (`expiration`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/*Data for the table `cache` */

/*Table structure for table `cache_locks` */

DROP TABLE IF EXISTS `cache_locks`;

CREATE TABLE `cache_locks` (
  `key` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `owner` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `expiration` int NOT NULL,
  PRIMARY KEY (`key`),
  KEY `cache_locks_expiration_index` (`expiration`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/*Data for the table `cache_locks` */

/*Table structure for table `failed_jobs` */

DROP TABLE IF EXISTS `failed_jobs`;

CREATE TABLE `failed_jobs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `uuid` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `connection` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `queue` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `payload` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `exception` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `failed_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `failed_jobs_uuid_unique` (`uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/*Data for the table `failed_jobs` */

/*Table structure for table `form_sections` */

DROP TABLE IF EXISTS `form_sections`;

CREATE TABLE `form_sections` (
  `id` int NOT NULL AUTO_INCREMENT,
  `form_id` int NOT NULL,
  `title` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
  `sort_order` int NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  KEY `idx_sections_form` (`form_id`,`sort_order`),
  CONSTRAINT `fk_sections_form` FOREIGN KEY (`form_id`) REFERENCES `forms` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

/*Data for the table `form_sections` */

insert  into `form_sections`(`id`,`form_id`,`title`,`description`,`sort_order`) values 
(1,1,'Equipo de Protección Personal','Responde sobre EPP y normas básicas.',1),
(2,1,'Procedimientos','Situaciones comunes y buenas prácticas.',2);

/*Table structure for table `forms` */

DROP TABLE IF EXISTS `forms`;

CREATE TABLE `forms` (
  `id` int NOT NULL AUTO_INCREMENT,
  `title` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
  `type` enum('quiz','evaluation') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'quiz',
  `scope` enum('general','area') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'general',
  `area` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `open_at` datetime DEFAULT NULL,
  `due_at` datetime DEFAULT NULL,
  `start_time` time DEFAULT NULL,
  `end_time` time DEFAULT NULL,
  `allow_save_draft` tinyint(1) NOT NULL DEFAULT '1',
  `shuffle_options` tinyint(1) NOT NULL DEFAULT '0',
  `created_by` int DEFAULT NULL,
  `active` tinyint(1) NOT NULL DEFAULT '1',
  `published` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_forms_scope_area` (`scope`,`area`),
  KEY `idx_forms_active_published` (`active`,`published`),
  KEY `idx_forms_due` (`due_at`),
  KEY `fk_forms_created_by` (`created_by`),
  CONSTRAINT `fk_forms_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

/*Data for the table `forms` */

insert  into `forms`(`id`,`title`,`description`,`type`,`scope`,`area`,`open_at`,`due_at`,`start_time`,`end_time`,`allow_save_draft`,`shuffle_options`,`created_by`,`active`,`published`,`created_at`,`updated_at`) values 
(1,'Inducción Seguridad','Lee con atención y responde todas las preguntas. Al finalizar se registrará la hora exacta de envío.','quiz','general',NULL,'2026-02-19 11:58:43','2026-02-26 11:58:43','08:00:00','18:00:00',1,0,1,1,1,'2026-02-19 11:58:43','2026-02-19 11:58:43');

/*Table structure for table `job_batches` */

DROP TABLE IF EXISTS `job_batches`;

CREATE TABLE `job_batches` (
  `id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `total_jobs` int NOT NULL,
  `pending_jobs` int NOT NULL,
  `failed_jobs` int NOT NULL,
  `failed_job_ids` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `options` mediumtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `cancelled_at` int DEFAULT NULL,
  `created_at` int NOT NULL,
  `finished_at` int DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/*Data for the table `job_batches` */

/*Table structure for table `migrations` */

DROP TABLE IF EXISTS `migrations`;

CREATE TABLE `migrations` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `migration` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `batch` int NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/*Data for the table `migrations` */

insert  into `migrations`(`id`,`migration`,`batch`) values 
(1,'0001_01_01_000000_create_users_table',1),
(2,'0001_01_01_000001_create_cache_table',1),
(3,'0001_01_01_000002_create_jobs_table',1),
(4,'2026_02_06_145752_create_rh_departamento_table',1),
(5,'2026_02_06_145752_create_rh_puesto_table',1),
(6,'2026_02_06_145753_create_rh_empleados_table',1);

/*Table structure for table `nom035_action_plan_attachments` */

DROP TABLE IF EXISTS `nom035_action_plan_attachments`;

CREATE TABLE `nom035_action_plan_attachments` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `action_plan_id` bigint unsigned NOT NULL,
  `original_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `stored_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `file_path` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `mime_type` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `file_size` bigint unsigned DEFAULT NULL,
  `uploaded_by_user_id` bigint unsigned DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_nom035_action_plan_attachments_plan_id` (`action_plan_id`),
  CONSTRAINT `fk_nom035_action_plan_attachments_plan` FOREIGN KEY (`action_plan_id`) REFERENCES `nom035_action_plans` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/*Data for the table `nom035_action_plan_attachments` */

insert  into `nom035_action_plan_attachments`(`id`,`action_plan_id`,`original_name`,`stored_name`,`file_path`,`mime_type`,`file_size`,`uploaded_by_user_id`,`created_at`) values 
(2,2,'ZCL51375H-RAL 8014 MATTE SDCR1375H (1).pdf','f1b0c06251b940ccb63c8cf4adb08dfc.pdf','uploads/nom035_action_plan_attachments\\f1b0c06251b940ccb63c8cf4adb08dfc.pdf','application/octet-stream',4136793,1,'2026-03-18 12:56:21'),
(3,2,'Safety data sheet of PRL30004 - BURGUNDY 12323.pdf','e717e292119e4dffaf95ccc17f48cead.pdf','uploads/nom035_action_plan_attachments\\e717e292119e4dffaf95ccc17f48cead.pdf','application/octet-stream',178921,1,'2026-03-18 12:56:31'),
(4,1,'mendoza_zuniga_jose_manuel_felix_nom_035_2026.pdf','3ddc2339a064407a82493ef012cbd2c0.pdf','uploads/nom035_action_plan_attachments\\3ddc2339a064407a82493ef012cbd2c0.pdf','application/octet-stream',22806,1,'2026-03-18 13:06:10'),
(5,1,'pngtree-cute-robot-holding-a-screwdriver-3d-illustration-png-image_13345891.png','ec371b48c79445fe8ecb1d40fb2985fa.png','uploads/nom035_action_plan_attachments\\ec371b48c79445fe8ecb1d40fb2985fa.png','application/octet-stream',63002,1,'2026-03-18 13:56:22'),
(6,2,'avatar_default.png.png','1c16ccd5ae4d43979038b9949b606a67.png','uploads/nom035_action_plan_attachments\\1c16ccd5ae4d43979038b9949b606a67.png','application/octet-stream',492025,1,'2026-03-19 08:04:23'),
(7,2,'productos.doc','c9526114561b4eb585a617ae0a650c36.doc','uploads/nom035_action_plan_attachments\\c9526114561b4eb585a617ae0a650c36.doc','application/octet-stream',1,1,'2026-03-19 09:58:58');

/*Table structure for table `nom035_action_plans` */

DROP TABLE IF EXISTS `nom035_action_plans`;

CREATE TABLE `nom035_action_plans` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `cycle_id` bigint unsigned NOT NULL,
  `department_id` bigint unsigned DEFAULT NULL,
  `department_name` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `risk_level` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `action_title` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `action_description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `responsible_name` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `responsible_user_id` int DEFAULT NULL,
  `due_date` date DEFAULT NULL,
  `status` enum('pendiente','en_proceso','completado','cancelado') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pendiente',
  `progress_percent` decimal(5,2) NOT NULL DEFAULT '0.00',
  `created_by_user_id` bigint unsigned DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_nom035_action_plans_cycle_id` (`cycle_id`),
  KEY `idx_nom035_action_plans_status` (`status`),
  KEY `idx_nom035_action_plans_due_date` (`due_date`),
  KEY `idx_nom035_action_plans_department_id` (`department_id`),
  CONSTRAINT `fk_nom035_action_plans_cycle` FOREIGN KEY (`cycle_id`) REFERENCES `nom035_cycles` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/*Data for the table `nom035_action_plans` */

insert  into `nom035_action_plans`(`id`,`cycle_id`,`department_id`,`department_name`,`risk_level`,`action_title`,`action_description`,`responsible_name`,`responsible_user_id`,`due_date`,`status`,`progress_percent`,`created_by_user_id`,`created_at`,`updated_at`) values 
(1,1,8,'CIUDAD DE MEXICO','Muy Alto','Jefe de Producción / Recursos Humanos','Jefe de Producción / Recursos Humanos','Jefe de Producción / Recursos Humanos',NULL,'2026-04-20','completado',50.00,1,'2026-03-18 08:51:11','2026-03-23 09:10:49'),
(2,1,39,'PUEBLA','Medio','Redistribución de carga laboral','Se reorganizarán actividades del área para reducir sobrecarga y definir prioridades por turno.','MENDOZA ZUÑIGA JOSE MANUEL FELIX',17,'2026-04-30','en_proceso',90.00,12,'2026-03-18 09:08:03','2026-03-19 10:44:47'),
(6,1,NULL,NULL,'Alto','Redistribución de carga laboral','Se realizará un análisis de cargas de trabajo y se redistribuirán actividades para evitar sobrecarga en empleados.',NULL,NULL,NULL,'pendiente',0.00,1,'2026-03-19 12:11:30','2026-03-19 12:11:30'),
(7,1,NULL,NULL,'Medio','Capacitación en liderazgo','Implementar curso de liderazgo y comunicación efectiva para supervisores y jefes de área.',NULL,NULL,NULL,'pendiente',0.00,1,'2026-03-19 12:12:10','2026-03-19 12:12:10'),
(8,1,NULL,NULL,NULL,'Control de horas extra','Implementar sistema de control de horas extra y autorización previa por supervisor.',NULL,NULL,NULL,'pendiente',0.00,1,'2026-03-19 12:13:10','2026-03-19 12:13:10'),
(9,1,NULL,NULL,'Medio','Programa de reconocimiento','Desarrollar programa mensual de reconocimiento al desempeño y cumplimiento de objetivos.',NULL,NULL,NULL,'pendiente',0.00,1,'2026-03-19 12:13:32','2026-03-19 12:13:32'),
(10,1,NULL,NULL,'Alto','Implementación de protocolo de acoso','Establecer protocolo de denuncia, investigación y sanción ante casos de acoso laboral.',NULL,NULL,NULL,'pendiente',0.00,1,'2026-03-19 12:14:17','2026-03-19 12:14:17'),
(11,1,NULL,NULL,'Bajo','Reuniones semanales de seguimiento','Implementar reuniones semanales para mejorar comunicación entre equipos y seguimiento de actividades.',NULL,NULL,NULL,'pendiente',0.00,1,'2026-03-19 12:14:49','2026-03-19 12:14:49'),
(12,1,NULL,NULL,'Medio','Definición de roles y responsabilidades','Actualizar descripciones de puesto y comunicar responsabilidades claramente a cada empleado.',NULL,NULL,NULL,'pendiente',0.00,1,'2026-03-19 12:15:12','2026-03-19 12:15:12'),
(13,1,NULL,NULL,'Medio','Taller de clima laboral','Realizar talleres de integración y mejora del ambiente laboral.',NULL,NULL,NULL,'pendiente',0.00,1,'2026-03-19 12:15:51','2026-03-19 12:15:51'),
(14,1,NULL,NULL,NULL,'Implementación de pausas activas','Establecer pausas activas de 5 minutos cada 2 horas de trabajo. o ejercicios de estiramiento',NULL,NULL,NULL,'pendiente',0.00,1,'2026-03-19 12:16:45','2026-03-19 12:16:45'),
(15,1,25,'GERENCIA DE RECURSOS HUMANOS','Medio','Programa de apoyo al empleado','Crear canal de apoyo psicológico y asesoría laboral para empleados.','SANCHEZ SANCHEZ ADELINA VIOLETA',14,NULL,'pendiente',55.00,1,'2026-03-19 12:17:38','2026-03-19 12:18:32'),
(16,1,1,'AGUASCALIENTES, GERENCIA DE RECURSOS HUMANOS','Muy Alto','hola esta es una prueba','falta de comunicacion entre estas 2 areas','SANCHEZ SANCHEZ ADELINA VIOLETA',14,'2026-03-23','pendiente',0.00,1,'2026-03-23 09:08:51','2026-03-23 09:08:51');

/*Table structure for table `nom035_answers` */

DROP TABLE IF EXISTS `nom035_answers`;

CREATE TABLE `nom035_answers` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `submission_id` bigint unsigned NOT NULL,
  `question_id` bigint unsigned NOT NULL,
  `answer_value` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_nom035_answers_submission_question` (`submission_id`,`question_id`),
  KEY `idx_nom035_answers_submission` (`submission_id`),
  KEY `idx_nom035_answers_question` (`question_id`),
  CONSTRAINT `fk_nom035_answers_question` FOREIGN KEY (`question_id`) REFERENCES `nom035_questions` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_nom035_answers_submission` FOREIGN KEY (`submission_id`) REFERENCES `nom035_submissions` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=990 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/*Data for the table `nom035_answers` */

insert  into `nom035_answers`(`id`,`submission_id`,`question_id`,`answer_value`,`created_at`,`updated_at`) values 
(705,51,1,'2','2026-03-13 12:47:04','2026-03-13 12:47:04'),
(706,51,3,'2','2026-03-13 12:47:06','2026-03-13 12:47:06'),
(707,51,2,'2','2026-03-13 12:47:08','2026-03-13 12:47:08'),
(708,51,4,'2','2026-03-13 12:47:09','2026-03-13 12:47:09'),
(709,51,5,'2','2026-03-13 12:47:13','2026-03-13 12:47:13'),
(710,51,6,'2','2026-03-13 12:47:14','2026-03-13 12:47:14'),
(711,51,7,'1','2026-03-13 12:47:16','2026-03-13 12:47:16'),
(712,51,8,'2','2026-03-13 12:47:17','2026-03-13 12:47:17'),
(713,51,9,'2','2026-03-13 12:47:18','2026-03-13 12:47:18'),
(714,51,10,'2','2026-03-13 12:47:20','2026-03-13 12:47:20'),
(715,51,12,'2','2026-03-13 12:47:21','2026-03-13 12:47:21'),
(716,51,11,'2','2026-03-13 12:47:22','2026-03-13 12:47:22'),
(717,51,13,'2','2026-03-13 12:47:26','2026-03-13 12:47:26'),
(718,51,14,'2','2026-03-13 12:47:26','2026-03-13 12:47:26'),
(719,51,15,'2','2026-03-13 12:47:27','2026-03-13 12:47:27'),
(720,51,16,'2','2026-03-13 12:47:42','2026-03-13 12:47:42'),
(721,51,17,'3','2026-03-13 12:47:43','2026-03-13 12:47:43'),
(722,51,18,'3','2026-03-13 12:47:45','2026-03-13 12:47:45'),
(723,51,19,'4','2026-03-13 12:47:45','2026-03-13 12:47:50'),
(724,51,20,'2','2026-03-13 12:47:49','2026-03-13 12:47:49'),
(725,51,21,'2','2026-03-13 12:47:51','2026-03-13 12:47:51'),
(726,51,24,'3','2026-03-13 12:47:53','2026-03-13 12:47:53'),
(727,51,22,'2','2026-03-13 12:47:53','2026-03-13 12:47:53'),
(728,51,23,'2','2026-03-13 12:47:56','2026-03-13 12:47:56'),
(729,51,25,'2','2026-03-13 12:47:57','2026-03-13 12:47:57'),
(730,51,26,'4','2026-03-13 12:47:59','2026-03-13 12:47:59'),
(731,51,27,'2','2026-03-13 12:48:00','2026-03-13 12:48:00'),
(732,51,28,'3','2026-03-13 12:48:02','2026-03-13 12:48:02'),
(733,51,33,'3','2026-03-13 12:48:03','2026-03-13 12:48:03'),
(734,51,34,'5','2026-03-13 12:48:05','2026-03-13 12:48:05'),
(735,51,35,'3','2026-03-13 12:48:05','2026-03-13 12:48:05'),
(736,51,36,'2','2026-03-13 12:48:08','2026-03-13 12:48:08'),
(737,51,37,'3','2026-03-13 12:48:08','2026-03-13 12:48:08'),
(738,51,41,'4','2026-03-13 12:48:10','2026-03-13 12:48:10'),
(739,51,42,'2','2026-03-13 12:48:11','2026-03-13 12:48:11'),
(740,51,29,'3','2026-03-13 12:48:14','2026-03-13 12:48:14'),
(741,51,30,'1','2026-03-13 12:48:14','2026-03-13 12:48:14'),
(742,51,31,'3','2026-03-13 12:48:31','2026-03-13 12:48:31'),
(743,51,32,'3','2026-03-13 12:48:31','2026-03-13 12:48:31'),
(744,51,38,'4','2026-03-13 12:48:33','2026-03-13 12:48:33'),
(745,51,39,'2','2026-03-13 12:48:34','2026-03-13 12:48:34'),
(746,51,40,'4','2026-03-13 12:48:37','2026-03-13 12:48:37'),
(747,51,43,'1','2026-03-13 12:48:37','2026-03-13 12:48:37'),
(748,51,44,'3','2026-03-13 12:48:39','2026-03-13 12:48:39'),
(749,51,45,'2','2026-03-13 12:48:39','2026-03-13 12:48:39'),
(750,51,46,'2','2026-03-13 12:48:42','2026-03-13 12:48:42'),
(751,51,47,'1','2026-03-13 12:48:43','2026-03-13 12:48:43'),
(752,51,48,'4','2026-03-13 12:48:45','2026-03-13 12:48:45'),
(753,51,49,'2','2026-03-13 12:48:45','2026-03-13 12:48:45'),
(754,51,50,'3','2026-03-13 12:48:51','2026-03-13 12:48:51'),
(755,51,51,'3','2026-03-13 12:48:53','2026-03-13 12:48:53'),
(756,51,52,'3','2026-03-13 12:48:56','2026-03-13 12:48:56'),
(757,51,53,'2','2026-03-13 12:48:57','2026-03-13 12:48:57'),
(758,51,54,'3','2026-03-13 12:49:12','2026-03-13 12:49:12'),
(759,51,55,'2','2026-03-13 12:49:12','2026-03-13 12:49:12'),
(760,51,56,'3','2026-03-13 12:49:15','2026-03-13 12:49:15'),
(761,51,57,'2','2026-03-13 12:49:15','2026-03-13 12:49:15'),
(762,51,60,'2','2026-03-13 12:49:18','2026-03-13 12:49:18'),
(763,51,61,'2','2026-03-13 12:49:18','2026-03-13 12:49:18'),
(764,51,58,'4','2026-03-13 12:49:25','2026-03-13 12:49:25'),
(765,51,59,'3','2026-03-13 12:49:25','2026-03-13 12:49:25'),
(766,51,62,'3','2026-03-13 12:49:40','2026-03-13 12:49:40'),
(767,51,64,'3','2026-03-13 12:49:41','2026-03-13 12:49:41'),
(768,51,63,'3','2026-03-13 12:49:42','2026-03-13 12:49:42'),
(769,51,65,'4','2026-03-13 12:49:43','2026-03-13 12:49:43'),
(770,51,66,'2','2026-03-13 12:49:46','2026-03-13 12:49:46'),
(771,51,69,'2','2026-03-13 12:49:49','2026-03-13 12:49:49'),
(772,51,68,'4','2026-03-13 12:49:49','2026-03-13 12:49:49'),
(773,51,73,'2','2026-03-13 12:49:51','2026-03-13 12:49:51'),
(774,51,67,'3','2026-03-13 12:49:53','2026-03-13 12:49:53'),
(775,51,70,'3','2026-03-13 12:49:57','2026-03-13 12:49:57'),
(776,51,71,'2','2026-03-13 12:49:58','2026-03-13 12:49:58'),
(777,51,72,'3','2026-03-13 12:50:00','2026-03-13 12:50:00'),
(778,51,74,'4','2026-03-13 12:50:00','2026-03-13 12:50:00'),
(779,51,76,'3','2026-03-13 12:50:05','2026-03-13 12:50:05'),
(780,51,75,'4','2026-03-13 12:50:05','2026-03-13 12:50:05'),
(781,51,77,'3','2026-03-13 12:50:09','2026-03-13 12:50:09'),
(782,51,86,'1','2026-03-13 12:50:10','2026-03-13 12:50:10'),
(783,51,87,'5','2026-03-13 12:50:12','2026-03-13 12:50:12'),
(784,51,88,'3','2026-03-13 12:50:12','2026-03-13 12:50:12'),
(785,51,89,'3','2026-03-13 12:50:20','2026-03-13 12:50:20'),
(786,51,84,'3','2026-03-13 12:50:20','2026-03-13 12:50:20'),
(787,51,85,'3','2026-03-13 12:50:23','2026-03-13 12:50:23'),
(788,51,90,'3','2026-03-13 12:50:25','2026-03-13 12:50:25'),
(789,51,91,'3','2026-03-13 12:50:26','2026-03-13 12:50:26'),
(790,51,96,'3','2026-03-13 12:50:29','2026-03-13 12:50:29'),
(791,51,97,'3','2026-03-13 12:50:30','2026-03-13 12:50:30'),
(792,51,78,'4','2026-03-13 12:50:31','2026-03-13 12:50:31'),
(793,51,79,'4','2026-03-13 12:50:34','2026-03-13 12:50:34'),
(794,51,80,'3','2026-03-13 12:50:34','2026-03-13 12:50:34'),
(795,51,81,'2','2026-03-13 12:50:37','2026-03-13 12:50:37'),
(796,51,82,'3','2026-03-13 12:50:37','2026-03-13 12:50:37'),
(797,51,92,'3','2026-03-13 12:50:39','2026-03-13 12:50:39'),
(798,51,83,'4','2026-03-13 12:50:42','2026-03-13 12:50:42'),
(799,51,93,'1','2026-03-13 12:50:43','2026-03-13 12:50:43'),
(800,51,94,'3','2026-03-13 12:50:45','2026-03-13 12:50:45'),
(801,51,95,'2','2026-03-13 12:50:45','2026-03-13 12:50:45'),
(802,51,98,'3','2026-03-13 12:50:48','2026-03-13 12:50:48'),
(803,51,99,'2','2026-03-13 12:50:48','2026-03-13 12:50:48'),
(804,51,100,'3','2026-03-13 12:50:51','2026-03-13 12:50:51'),
(805,51,101,'2','2026-03-13 12:50:51','2026-03-13 12:50:51'),
(806,51,102,'5','2026-03-13 12:50:55','2026-03-13 12:50:55'),
(807,51,103,'2','2026-03-13 12:50:55','2026-03-13 12:50:55'),
(808,51,104,'3','2026-03-13 12:50:58','2026-03-13 12:50:58'),
(809,51,105,'3','2026-03-13 12:50:58','2026-03-13 12:50:58'),
(810,51,106,'2','2026-03-13 12:51:01','2026-03-13 12:51:01'),
(811,51,107,'3','2026-03-13 12:51:03','2026-03-13 12:51:03'),
(812,51,119,'3','2026-03-13 12:51:04','2026-03-13 12:51:04'),
(813,51,120,'4','2026-03-13 12:51:07','2026-03-13 12:51:07'),
(814,51,121,'5','2026-03-13 12:51:10','2026-03-13 12:51:10'),
(815,51,122,'4','2026-03-13 12:51:10','2026-03-13 12:51:10'),
(816,51,123,'3','2026-03-13 12:51:13','2026-03-13 12:51:13'),
(817,51,124,'4','2026-03-13 12:51:15','2026-03-13 12:51:15'),
(818,51,125,'3','2026-03-13 12:51:15','2026-03-13 12:51:15'),
(819,51,108,'4','2026-03-13 12:51:18','2026-03-13 12:51:25'),
(820,51,126,'3','2026-03-13 12:51:21','2026-03-13 12:51:21'),
(821,51,109,'2','2026-03-13 12:51:24','2026-03-13 12:51:24'),
(822,51,110,'3','2026-03-13 12:51:26','2026-03-13 12:51:26'),
(823,51,111,'3','2026-03-13 12:51:28','2026-03-13 12:51:28'),
(824,51,112,'3','2026-03-13 12:51:29','2026-03-13 12:51:29'),
(825,51,113,'3','2026-03-13 12:51:32','2026-03-13 12:51:32'),
(826,51,114,'4','2026-03-13 12:51:36','2026-03-13 12:51:36'),
(827,51,115,'5','2026-03-13 12:51:36','2026-03-13 12:51:36'),
(828,51,117,'3','2026-03-13 12:51:39','2026-03-13 12:51:39'),
(829,51,118,'2','2026-03-13 12:51:39','2026-03-13 12:51:39'),
(830,51,127,'3','2026-03-13 12:51:41','2026-03-13 12:51:41'),
(831,51,128,'4','2026-03-13 12:51:42','2026-03-13 12:51:42'),
(832,51,129,'4','2026-03-13 12:51:44','2026-03-13 12:51:44'),
(833,51,130,'4','2026-03-13 12:51:47','2026-03-13 12:51:47'),
(834,51,131,'4','2026-03-13 12:51:47','2026-03-13 12:51:47'),
(835,51,133,'5','2026-03-13 12:51:51','2026-03-13 12:51:51'),
(836,51,134,'4','2026-03-13 12:51:51','2026-03-13 12:51:51'),
(837,51,132,'3','2026-03-13 12:51:53','2026-03-13 12:51:53'),
(838,51,190,'2','2026-03-13 12:52:03','2026-03-13 12:52:03'),
(839,51,191,'4','2026-03-13 12:52:03','2026-03-13 12:52:03'),
(840,51,192,'2','2026-03-13 12:52:09','2026-03-13 12:52:09'),
(841,51,193,'3','2026-03-13 12:52:10','2026-03-13 12:52:10'),
(842,51,194,'1','2026-03-13 12:52:15','2026-03-13 12:52:15'),
(843,51,196,'4','2026-03-13 12:52:17','2026-03-13 12:52:17'),
(844,51,198,'2','2026-03-13 12:52:20','2026-03-13 12:52:20'),
(845,51,197,'3','2026-03-13 12:52:20','2026-03-13 12:52:20'),
(846,51,199,'3','2026-03-13 12:52:21','2026-03-13 12:52:21'),
(847,51,200,'2','2026-03-13 12:52:24','2026-03-13 12:52:24'),
(848,51,201,'5','2026-03-13 12:52:25','2026-03-13 12:52:25'),
(849,51,202,'5','2026-03-13 12:52:27','2026-03-13 12:52:27'),
(850,51,188,'1','2026-03-13 12:52:34','2026-03-13 12:52:34'),
(851,51,189,'1','2026-03-13 12:52:34','2026-03-13 12:52:34'),
(852,51,195,'1','2026-03-13 12:52:45','2026-03-13 12:52:45'),
(853,52,1,'2','2026-03-13 14:03:33','2026-03-13 14:03:33'),
(854,52,2,'2','2026-03-13 14:03:35','2026-03-13 14:03:35'),
(855,52,3,'2','2026-03-13 14:03:36','2026-03-13 14:03:36'),
(856,52,4,'2','2026-03-13 14:03:39','2026-03-13 14:03:39'),
(857,52,5,'2','2026-03-13 14:03:40','2026-03-13 14:03:40'),
(858,52,6,'2','2026-03-13 14:03:43','2026-03-13 14:03:43'),
(859,52,7,'2','2026-03-13 14:03:44','2026-03-13 14:03:44'),
(860,52,8,'2','2026-03-13 14:03:48','2026-03-13 14:03:48'),
(861,52,9,'2','2026-03-13 14:03:48','2026-03-13 14:03:48'),
(862,52,10,'2','2026-03-13 14:03:51','2026-03-13 14:03:51'),
(863,52,11,'2','2026-03-13 14:03:52','2026-03-13 14:03:52'),
(864,52,12,'2','2026-03-13 14:03:54','2026-03-13 14:03:54'),
(865,52,13,'2','2026-03-13 14:03:54','2026-03-13 14:03:54'),
(866,52,14,'2','2026-03-13 14:03:55','2026-03-13 14:03:55'),
(867,52,15,'2','2026-03-13 14:03:57','2026-03-13 14:03:57'),
(869,54,1,'2','2026-03-17 08:23:07','2026-03-17 08:23:07'),
(870,54,2,'2','2026-03-17 08:23:09','2026-03-17 08:23:09'),
(871,54,3,'2','2026-03-17 08:23:10','2026-03-17 08:23:10'),
(872,54,4,'2','2026-03-17 08:23:11','2026-03-17 08:23:11'),
(873,54,5,'2','2026-03-17 08:23:13','2026-03-17 08:23:13'),
(874,54,6,'2','2026-03-17 08:23:14','2026-03-17 08:23:14'),
(875,54,7,'2','2026-03-17 08:23:16','2026-03-17 08:23:16'),
(876,54,8,'2','2026-03-17 08:23:18','2026-03-17 08:23:18'),
(877,54,9,'2','2026-03-17 08:23:18','2026-03-17 08:23:18'),
(878,54,11,'2','2026-03-17 08:23:22','2026-03-17 08:23:22'),
(879,54,12,'2','2026-03-17 08:23:22','2026-03-17 08:23:22'),
(880,54,13,'2','2026-03-17 08:23:23','2026-03-17 08:23:23'),
(881,54,14,'2','2026-03-17 08:23:26','2026-03-17 08:23:26'),
(882,54,15,'2','2026-03-17 08:23:27','2026-03-17 08:23:27'),
(883,54,10,'2','2026-03-17 08:23:30','2026-03-17 08:23:30'),
(884,55,1,'2','2026-03-17 10:16:52','2026-03-17 10:16:52'),
(885,55,2,'2','2026-03-17 10:16:53','2026-03-17 10:16:53'),
(886,55,3,'2','2026-03-17 10:16:54','2026-03-17 10:16:54'),
(887,55,4,'2','2026-03-17 10:16:56','2026-03-17 10:16:56'),
(888,55,5,'2','2026-03-17 10:16:56','2026-03-17 10:16:56'),
(889,55,6,'2','2026-03-17 10:17:01','2026-03-17 10:17:01'),
(890,55,7,'2','2026-03-17 10:17:01','2026-03-17 10:17:01'),
(891,55,8,'2','2026-03-17 10:17:02','2026-03-17 10:17:02'),
(892,55,9,'2','2026-03-17 10:17:07','2026-03-17 10:17:07'),
(893,55,10,'2','2026-03-17 10:17:07','2026-03-17 10:17:07'),
(894,55,11,'2','2026-03-17 10:17:11','2026-03-17 10:17:11'),
(895,55,12,'2','2026-03-17 10:17:12','2026-03-17 10:17:12'),
(896,55,13,'2','2026-03-17 10:17:13','2026-03-17 10:17:14'),
(897,55,14,'2','2026-03-17 10:17:16','2026-03-17 10:17:16'),
(898,55,15,'2','2026-03-17 10:17:17','2026-03-17 10:17:17'),
(899,56,1,'2','2026-03-17 10:18:54','2026-03-17 10:18:54'),
(900,56,2,'2','2026-03-17 10:18:55','2026-03-17 10:18:55'),
(901,56,3,'2','2026-03-17 10:18:56','2026-03-17 10:18:56'),
(902,56,4,'2','2026-03-17 10:18:56','2026-03-17 10:18:56'),
(903,56,5,'2','2026-03-17 10:18:58','2026-03-17 10:18:58'),
(904,56,6,'2','2026-03-17 10:18:59','2026-03-17 10:18:59'),
(905,56,7,'2','2026-03-17 10:18:59','2026-03-17 10:18:59'),
(906,56,8,'2','2026-03-17 10:19:02','2026-03-17 10:19:02'),
(907,56,9,'2','2026-03-17 10:19:03','2026-03-17 10:19:03'),
(908,56,10,'2','2026-03-17 10:19:06','2026-03-17 10:19:06'),
(909,56,11,'2','2026-03-17 10:19:06','2026-03-17 10:19:06'),
(910,56,12,'2','2026-03-17 10:19:07','2026-03-17 10:19:07'),
(911,56,13,'2','2026-03-17 10:19:10','2026-03-17 10:19:10'),
(912,56,14,'2','2026-03-17 10:19:11','2026-03-17 10:19:11'),
(913,56,15,'2','2026-03-17 10:19:14','2026-03-17 10:19:14'),
(915,57,1,'2','2026-03-17 10:20:24','2026-03-17 10:20:24'),
(916,57,2,'2','2026-03-17 10:20:25','2026-03-17 10:20:25'),
(917,57,3,'2','2026-03-17 10:20:25','2026-03-17 10:20:25'),
(918,57,4,'2','2026-03-17 10:20:26','2026-03-17 10:20:26'),
(919,57,5,'2','2026-03-17 10:20:28','2026-03-17 10:20:28'),
(920,57,6,'2','2026-03-17 10:20:28','2026-03-17 10:20:28'),
(921,57,7,'2','2026-03-17 10:20:29','2026-03-17 10:20:29'),
(922,57,8,'2','2026-03-17 10:21:44','2026-03-17 10:21:44'),
(923,57,9,'2','2026-03-17 10:21:44','2026-03-17 10:21:44'),
(924,57,10,'2','2026-03-17 10:21:47','2026-03-17 10:21:47'),
(925,57,11,'2','2026-03-17 10:21:47','2026-03-17 10:21:47'),
(926,57,13,'2','2026-03-17 10:21:50','2026-03-17 10:21:50'),
(927,57,12,'2','2026-03-17 10:21:50','2026-03-17 10:21:50'),
(928,57,14,'2','2026-03-17 10:21:53','2026-03-17 10:21:53'),
(929,57,15,'2','2026-03-17 10:21:53','2026-03-17 10:21:53'),
(930,58,1,'2','2026-03-17 11:44:52','2026-03-17 11:44:52'),
(931,58,2,'2','2026-03-17 11:44:52','2026-03-17 11:44:52'),
(932,58,3,'2','2026-03-17 11:44:53','2026-03-17 11:44:53'),
(933,58,4,'2','2026-03-17 11:44:56','2026-03-17 11:44:56'),
(934,58,5,'2','2026-03-17 11:44:57','2026-03-17 11:44:57'),
(935,58,6,'2','2026-03-17 11:44:57','2026-03-17 11:44:57'),
(936,58,7,'2','2026-03-17 11:45:01','2026-03-17 11:45:01'),
(937,58,8,'2','2026-03-17 11:45:02','2026-03-17 11:45:02'),
(938,58,9,'2','2026-03-17 11:45:02','2026-03-17 11:45:02'),
(939,58,10,'2','2026-03-17 11:45:05','2026-03-17 11:45:05'),
(940,58,11,'2','2026-03-17 11:45:05','2026-03-17 11:45:05'),
(941,58,12,'2','2026-03-17 11:45:06','2026-03-17 11:45:06'),
(942,58,13,'2','2026-03-17 11:45:10','2026-03-17 11:45:10'),
(943,58,14,'2','2026-03-17 11:45:11','2026-03-17 11:45:11'),
(944,58,15,'2','2026-03-17 11:45:13','2026-03-17 11:45:13'),
(945,59,1,'2','2026-03-17 11:46:07','2026-03-17 11:46:07'),
(946,59,2,'2','2026-03-17 11:46:08','2026-03-17 11:46:08'),
(947,59,3,'2','2026-03-17 11:46:09','2026-03-17 11:46:09'),
(948,59,4,'2','2026-03-17 11:46:09','2026-03-17 11:46:09'),
(949,59,5,'2','2026-03-17 11:46:12','2026-03-17 11:46:12'),
(950,59,6,'2','2026-03-17 11:46:12','2026-03-17 11:46:12'),
(951,59,7,'2','2026-03-17 11:46:13','2026-03-17 11:46:13'),
(952,59,8,'2','2026-03-17 11:46:17','2026-03-17 11:46:17'),
(953,59,9,'2','2026-03-17 11:46:18','2026-03-17 11:46:18'),
(954,59,10,'2','2026-03-17 11:46:18','2026-03-17 11:46:18'),
(955,59,11,'2','2026-03-17 11:46:22','2026-03-17 11:46:22'),
(956,59,12,'2','2026-03-17 11:46:22','2026-03-17 11:46:22'),
(957,59,13,'2','2026-03-17 11:46:23','2026-03-17 11:46:23'),
(958,59,14,'2','2026-03-17 11:46:26','2026-03-17 11:46:26'),
(959,59,15,'2','2026-03-17 11:46:26','2026-03-17 11:46:26'),
(960,60,1,'2','2026-03-17 11:48:39','2026-03-17 11:48:39'),
(961,60,2,'2','2026-03-17 11:48:40','2026-03-17 11:48:40'),
(962,60,3,'2','2026-03-17 11:48:41','2026-03-17 11:48:41'),
(963,60,4,'2','2026-03-17 11:48:43','2026-03-17 11:48:43'),
(964,60,5,'2','2026-03-17 11:48:44','2026-03-17 11:48:44'),
(965,60,6,'2','2026-03-17 11:48:44','2026-03-17 11:48:44'),
(966,60,7,'2','2026-03-17 11:48:48','2026-03-17 11:48:48'),
(967,60,8,'2','2026-03-17 11:48:49','2026-03-17 11:48:49'),
(968,60,9,'2','2026-03-17 11:48:49','2026-03-17 11:48:49'),
(969,60,10,'2','2026-03-17 11:48:52','2026-03-17 11:48:52'),
(970,60,11,'2','2026-03-17 11:48:52','2026-03-17 11:48:52'),
(971,60,12,'2','2026-03-17 11:48:53','2026-03-17 11:48:53'),
(972,60,13,'2','2026-03-17 11:48:59','2026-03-17 11:48:59'),
(973,60,14,'2','2026-03-17 11:48:59','2026-03-17 11:48:59'),
(974,60,15,'2','2026-03-17 11:48:59','2026-03-17 11:48:59'),
(975,61,1,'2','2026-03-19 10:00:49','2026-03-19 10:00:49'),
(976,61,2,'2','2026-03-19 10:00:52','2026-03-19 10:00:52'),
(977,61,3,'2','2026-03-19 10:00:52','2026-03-19 10:00:52'),
(978,61,4,'2','2026-03-19 10:00:56','2026-03-19 10:00:56'),
(979,61,5,'2','2026-03-19 10:00:57','2026-03-19 10:00:57'),
(980,61,6,'2','2026-03-19 10:00:57','2026-03-19 10:00:57'),
(981,61,8,'2','2026-03-19 10:01:01','2026-03-19 10:01:01'),
(982,61,9,'2','2026-03-19 10:01:01','2026-03-19 10:01:01'),
(983,61,10,'2','2026-03-19 10:01:02','2026-03-19 10:01:02'),
(984,61,7,'2','2026-03-19 10:01:04','2026-03-19 10:01:04'),
(985,61,12,'2','2026-03-19 10:01:07','2026-03-19 10:01:07'),
(986,61,13,'2','2026-03-19 10:01:08','2026-03-19 10:01:08'),
(987,61,14,'2','2026-03-19 10:01:08','2026-03-19 10:01:08'),
(988,61,15,'2','2026-03-19 10:01:09','2026-03-19 10:01:09'),
(989,61,11,'2','2026-03-19 10:01:11','2026-03-19 10:01:11');

/*Table structure for table `nom035_audit_files` */

DROP TABLE IF EXISTS `nom035_audit_files`;

CREATE TABLE `nom035_audit_files` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `cycle_id` bigint unsigned NOT NULL,
  `is_ready` tinyint(1) NOT NULL DEFAULT '0',
  `notes` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `generated_at` datetime DEFAULT NULL,
  `generated_by_user_id` bigint unsigned DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_nom035_audit_files_cycle` (`cycle_id`),
  CONSTRAINT `fk_nom035_audit_files_cycle` FOREIGN KEY (`cycle_id`) REFERENCES `nom035_cycles` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/*Data for the table `nom035_audit_files` */

insert  into `nom035_audit_files`(`id`,`cycle_id`,`is_ready`,`notes`,`generated_at`,`generated_by_user_id`,`created_at`,`updated_at`) values 
(1,1,0,NULL,'2026-03-23 12:49:18',1,'2026-03-18 09:15:07','2026-03-23 12:49:18');

/*Table structure for table `nom035_cycle_approvals` */

DROP TABLE IF EXISTS `nom035_cycle_approvals`;

CREATE TABLE `nom035_cycle_approvals` (
  `cycle_id` bigint unsigned NOT NULL,
  `user_id` int NOT NULL,
  `approved_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`cycle_id`,`user_id`),
  KEY `fk_nca_user` (`user_id`),
  CONSTRAINT `fk_nca_cycle` FOREIGN KEY (`cycle_id`) REFERENCES `nom035_cycles` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_nca_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

/*Data for the table `nom035_cycle_approvals` */

/*Table structure for table `nom035_cycle_questions` */

DROP TABLE IF EXISTS `nom035_cycle_questions`;

CREATE TABLE `nom035_cycle_questions` (
  `cycle_id` bigint unsigned NOT NULL,
  `question_id` bigint unsigned NOT NULL,
  `order_no` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`cycle_id`,`question_id`),
  KEY `idx_nom035_cq_order` (`cycle_id`,`order_no`),
  KEY `idx_nom035_cq_question` (`question_id`),
  CONSTRAINT `fk_nom035_cq_cycle` FOREIGN KEY (`cycle_id`) REFERENCES `nom035_cycles` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_nom035_cq_question` FOREIGN KEY (`question_id`) REFERENCES `nom035_questions` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/*Data for the table `nom035_cycle_questions` */

insert  into `nom035_cycle_questions`(`cycle_id`,`question_id`,`order_no`) values 
(1,1,1),
(1,2,2),
(1,3,3),
(1,4,4),
(1,5,5),
(1,6,6),
(1,7,7),
(1,8,8),
(1,9,9),
(1,10,10),
(1,11,11),
(1,12,12),
(1,13,13),
(1,14,14),
(1,15,15),
(1,16,16),
(1,188,3001),
(1,189,3002),
(1,190,3003),
(1,191,3004),
(1,192,3005),
(1,193,3006),
(1,194,3007),
(1,195,3008),
(1,196,3009),
(1,197,3010),
(1,198,3011),
(1,199,3012),
(1,200,3013),
(1,201,3014),
(1,202,3015),
(1,17,2202002),
(1,18,2203003),
(1,19,2204004),
(1,24,2204009),
(1,20,2205005),
(1,21,2205006),
(1,22,2206007),
(1,23,2206008),
(1,25,2207010),
(1,26,2207011),
(1,27,2208012),
(1,28,2208013),
(1,33,2209018),
(1,34,2209019),
(1,35,2210020),
(1,36,2210021),
(1,37,2210022),
(1,41,2211026),
(1,42,2211027),
(1,29,2212014),
(1,30,2212015),
(1,31,2213016),
(1,32,2214017),
(1,38,2215023),
(1,39,2215024),
(1,40,2215025),
(1,43,2216028),
(1,44,2216029),
(1,45,2217030),
(1,46,2217031),
(1,47,2217032),
(1,48,2218033),
(1,49,2218034),
(1,50,2218035),
(1,51,2218036),
(1,52,2218037),
(1,53,2218038),
(1,54,2218039),
(1,55,2218040),
(1,56,2219041),
(1,57,2219042),
(1,58,2219043),
(1,59,2220044),
(1,60,2220045),
(1,61,2220046),
(1,62,3301001),
(1,64,3301003),
(1,63,3302002),
(1,65,3302004),
(1,66,3303005),
(1,67,3304006),
(1,73,3304012),
(1,68,3305007),
(1,69,3305008),
(1,70,3306009),
(1,71,3306010),
(1,72,3306011),
(1,74,3307013),
(1,75,3307014),
(1,76,3308015),
(1,77,3308016),
(1,86,3309025),
(1,87,3309026),
(1,88,3309027),
(1,89,3309028),
(1,84,3310023),
(1,85,3310024),
(1,90,3311029),
(1,91,3311030),
(1,96,3312035),
(1,97,3312036),
(1,78,3313017),
(1,79,3313018),
(1,80,3314019),
(1,81,3314020),
(1,82,3315021),
(1,83,3315022),
(1,92,3316031),
(1,93,3316032),
(1,94,3316033),
(1,95,3316034),
(1,98,3317037),
(1,99,3317038),
(1,100,3317039),
(1,101,3317040),
(1,102,3317041),
(1,103,3318042),
(1,104,3318043),
(1,105,3318044),
(1,106,3318045),
(1,107,3318046),
(1,119,3319057),
(1,120,3319058),
(1,121,3319059),
(1,122,3319060),
(1,123,3319061),
(1,124,3319062),
(1,125,3319063),
(1,126,3319064),
(1,108,3320047),
(1,109,3320048),
(1,110,3321049),
(1,111,3321050),
(1,112,3321051),
(1,113,3321052),
(1,114,3322053),
(1,115,3322054),
(1,117,3323055),
(1,118,3323056),
(1,127,3324065),
(1,128,3324066),
(1,129,3324067),
(1,130,3324068),
(1,131,3325069),
(1,132,3325070),
(1,133,3325071),
(1,134,3325072);

/*Table structure for table `nom035_cycle_sections` */

DROP TABLE IF EXISTS `nom035_cycle_sections`;

CREATE TABLE `nom035_cycle_sections` (
  `cycle_id` bigint unsigned NOT NULL,
  `section_id` bigint unsigned NOT NULL,
  `order_no` int NOT NULL DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`cycle_id`,`section_id`),
  KEY `idx_nom035_cs_cycle_order` (`cycle_id`,`order_no`),
  KEY `idx_nom035_cs_section` (`section_id`),
  CONSTRAINT `fk_nom035_cs_cycle` FOREIGN KEY (`cycle_id`) REFERENCES `nom035_cycles` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_nom035_cs_section` FOREIGN KEY (`section_id`) REFERENCES `nom035_sections` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/*Data for the table `nom035_cycle_sections` */

insert  into `nom035_cycle_sections`(`cycle_id`,`section_id`,`order_no`,`created_at`) values 
(1,29,2201,'2026-02-25 08:59:30'),
(1,30,2202,'2026-02-25 08:59:30'),
(1,31,2203,'2026-02-25 08:59:30'),
(1,32,2204,'2026-02-25 08:59:30'),
(1,33,2205,'2026-02-25 08:59:30'),
(1,34,2206,'2026-02-25 08:59:30'),
(1,35,2207,'2026-02-25 08:59:30'),
(1,36,2208,'2026-02-25 08:59:30'),
(1,37,2209,'2026-02-25 08:59:30'),
(1,38,2210,'2026-02-25 08:59:30'),
(1,39,2211,'2026-02-25 08:59:30'),
(1,40,2212,'2026-02-25 08:59:30'),
(1,41,2213,'2026-02-25 08:59:30'),
(1,42,2214,'2026-02-25 08:59:30'),
(1,43,2215,'2026-02-25 08:59:30'),
(1,44,2216,'2026-02-25 08:59:30'),
(1,45,2217,'2026-02-25 08:59:30'),
(1,46,2218,'2026-02-25 08:59:30'),
(1,47,2219,'2026-02-25 08:59:30'),
(1,48,2220,'2026-02-25 08:59:30'),
(1,49,3301,'2026-02-25 08:59:30'),
(1,50,3302,'2026-02-25 08:59:30'),
(1,51,3303,'2026-02-25 08:59:30'),
(1,52,3304,'2026-02-25 08:59:30'),
(1,53,3305,'2026-02-25 08:59:30'),
(1,54,3306,'2026-02-25 08:59:30'),
(1,55,3307,'2026-02-25 08:59:30'),
(1,56,3308,'2026-02-25 08:59:30'),
(1,57,3309,'2026-02-25 08:59:30'),
(1,58,3310,'2026-02-25 08:59:30'),
(1,59,3311,'2026-02-25 08:59:30'),
(1,60,3312,'2026-02-25 08:59:30'),
(1,61,3313,'2026-02-25 08:59:30'),
(1,62,3314,'2026-02-25 08:59:30'),
(1,63,3315,'2026-02-25 08:59:30'),
(1,64,3316,'2026-02-25 08:59:30'),
(1,65,3317,'2026-02-25 08:59:30'),
(1,66,3318,'2026-02-25 08:59:30'),
(1,67,3319,'2026-02-25 08:59:30'),
(1,68,3320,'2026-02-25 08:59:30'),
(1,69,3321,'2026-02-25 08:59:30'),
(1,70,3322,'2026-02-25 08:59:30'),
(1,71,3323,'2026-02-25 08:59:30'),
(1,72,3324,'2026-02-25 08:59:30'),
(1,73,3325,'2026-02-25 08:59:30');

/*Table structure for table `nom035_cycles` */

DROP TABLE IF EXISTS `nom035_cycles`;

CREATE TABLE `nom035_cycles` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `year` int NOT NULL,
  `title` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `start_at` datetime NOT NULL,
  `due_at` datetime NOT NULL,
  `status` enum('draft','active','closed') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'draft',
  `created_by_user_id` bigint unsigned NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_nom035_cycles_year` (`year`),
  KEY `idx_nom035_cycles_status` (`status`),
  KEY `idx_nom035_cycles_dates` (`start_at`,`due_at`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/*Data for the table `nom035_cycles` */

insert  into `nom035_cycles`(`id`,`year`,`title`,`start_at`,`due_at`,`status`,`created_by_user_id`,`created_at`,`updated_at`) values 
(1,2026,'NOM-035 2026','2026-01-31 16:50:00','2026-04-23 23:59:00','active',1,'2026-02-20 12:18:38','2026-03-12 08:27:17');

/*Table structure for table `nom035_device_tokens` */

DROP TABLE IF EXISTS `nom035_device_tokens`;

CREATE TABLE `nom035_device_tokens` (
  `user_id` int NOT NULL,
  `fcm_token` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `platform` enum('android','ios','web') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`),
  KEY `idx_nom035_device_tokens_platform` (`platform`),
  KEY `idx_nom035_device_tokens_token` (`fcm_token`),
  CONSTRAINT `fk_nom035_device_tokens_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

/*Data for the table `nom035_device_tokens` */

insert  into `nom035_device_tokens`(`user_id`,`fcm_token`,`platform`,`updated_at`) values 
(5,'dksjfh23498y23498ysdf','android','2026-02-20 12:20:22');

/*Table structure for table `nom035_evidences` */

DROP TABLE IF EXISTS `nom035_evidences`;

CREATE TABLE `nom035_evidences` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `cycle_id` bigint unsigned NOT NULL,
  `action_plan_id` bigint unsigned DEFAULT NULL,
  `evidence_type` enum('policy','diffusion','training','diagnostic','action_plan','action_execution','stps_support') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `title` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `file_url` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `file_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `uploaded_by_user_id` bigint unsigned DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_nom035_evidences_cycle_id` (`cycle_id`),
  KEY `idx_nom035_evidences_action_plan_id` (`action_plan_id`),
  KEY `idx_nom035_evidences_type` (`evidence_type`),
  CONSTRAINT `fk_nom035_evidences_action_plan` FOREIGN KEY (`action_plan_id`) REFERENCES `nom035_action_plans` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_nom035_evidences_cycle` FOREIGN KEY (`cycle_id`) REFERENCES `nom035_cycles` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/*Data for the table `nom035_evidences` */

insert  into `nom035_evidences`(`id`,`cycle_id`,`action_plan_id`,`evidence_type`,`title`,`file_url`,`file_name`,`uploaded_by_user_id`,`created_at`) values 
(3,1,1,'action_plan','Plan de acción área producción','/uploads/nom035_evidence/be19786dfa6e40c5b34f4383fe7429a3.pdf','Safety data sheet of PRL30004 - BURGUNDY 12323.pdf',1,'2026-03-19 12:29:39'),
(4,1,14,'action_execution','Evidencia pausas activas implementadas','/uploads/nom035_evidence/6e5855228d37415cb588fed46ed9c80d.pdf','PNT60107 HYTEX BLACK 14154.pdf',1,'2026-03-19 12:30:52'),
(5,1,7,'training','Capacitación liderazgo supervisores','/uploads/nom035_evidence/d02c7a1b20f24e708322afcfc20fd3bd.jpg','google-anime-girl-windows-m9hyrkji4z3f4x99.jpg',1,'2026-03-19 12:32:29'),
(6,1,13,'stps_support','Carteles NOM-035 en áreas comunes','/uploads/nom035_evidence/f1438f3872014ef4aebcba0693183407.pptx','CONSULTAR TDS.pptx',1,'2026-03-19 12:43:23'),
(8,1,16,'action_execution','12345667','/uploads/nom035_evidence/b96dfb86f80447f7a4fda9b9e1676f3b.png','favicon.png',1,'2026-03-23 11:07:32'),
(9,1,NULL,'policy','POLITICA VITRACOAT','assets/docs/POLITICA VITRACOAT.pdf',NULL,1,'2026-03-23 15:57:40');

/*Table structure for table `nom035_notification_log` */

DROP TABLE IF EXISTS `nom035_notification_log`;

CREATE TABLE `nom035_notification_log` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `cycle_id` bigint unsigned NOT NULL,
  `user_id` int NOT NULL,
  `type` enum('start','reminder','due_today','expired') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `channel` enum('push','sms','whatsapp') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `provider_id` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `sent_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_nom035_notif_cycle` (`cycle_id`),
  KEY `idx_nom035_notif_user` (`user_id`),
  KEY `idx_nom035_notif_type` (`type`),
  KEY `idx_nom035_notif_channel` (`channel`),
  KEY `idx_nom035_notif_sent_at` (`sent_at`),
  KEY `idx_nom035_notif_cycle_user` (`cycle_id`,`user_id`),
  CONSTRAINT `fk_nom035_notif_cycle` FOREIGN KEY (`cycle_id`) REFERENCES `nom035_cycles` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_nom035_notif_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

/*Data for the table `nom035_notification_log` */

insert  into `nom035_notification_log`(`id`,`cycle_id`,`user_id`,`type`,`channel`,`provider_id`,`sent_at`) values 
(1,1,5,'start','push','firebase_123456','2026-02-20 12:20:33');

/*Table structure for table `nom035_questions` */

DROP TABLE IF EXISTS `nom035_questions`;

CREATE TABLE `nom035_questions` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `section_id` bigint unsigned DEFAULT NULL,
  `guide` enum('I','II','III','IV','V') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `category` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `question_text` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `response_type` enum('likert','yes_no','multiple','open') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `options_json` json DEFAULT NULL,
  `order_no` int NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `instruction_text` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `help_text` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `dimension` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `domain` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `reverse_scoring` tinyint(1) NOT NULL DEFAULT '0',
  `weight` decimal(6,2) NOT NULL DEFAULT '1.00',
  PRIMARY KEY (`id`),
  KEY `idx_nom035_questions_guide` (`guide`),
  KEY `idx_nom035_questions_active` (`is_active`),
  KEY `idx_nom035_questions_order` (`guide`,`order_no`),
  KEY `idx_nom035_questions_category` (`category`),
  KEY `idx_nom035_questions_section_order` (`section_id`,`order_no`),
  CONSTRAINT `fk_nom035_questions_section` FOREIGN KEY (`section_id`) REFERENCES `nom035_sections` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=204 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/*Data for the table `nom035_questions` */

insert  into `nom035_questions`(`id`,`section_id`,`guide`,`category`,`question_text`,`response_type`,`options_json`,`order_no`,`is_active`,`created_at`,`updated_at`,`instruction_text`,`help_text`,`dimension`,`domain`,`reverse_scoring`,`weight`) values 
(1,1,'I','Acontecimiento traumático severo','¿Ha presenciado o sufrido alguna vez, durante o con motivo del trabajo un acontecimiento como los siguientes: Accidente que tenga como consecuencia la muerte, la pérdida de un miembro o una lesión grave; Asaltos; Actos violentos que derivaron en lesiones graves; Secuestro; Amenazas; o Cualquier otro que ponga en riesgo su vida o salud, y/o la de otras personas?','yes_no','[{\"label\": \"Sí\", \"value\": 1}, {\"label\": \"No\", \"value\": 0}]',1,1,'2026-02-25 07:49:06','2026-03-13 13:02:14',NULL,NULL,NULL,'Acontecimiento traumático severo',0,1.00),
(2,1,'I','Recuerdos persistentes (último mes)','¿Ha tenido recuerdos recurrentes sobre el acontecimiento que le provocan malestares?','yes_no','[{\"label\": \"Sí\", \"value\": 1}, {\"label\": \"No\", \"value\": 0}]',2,1,'2026-02-25 07:49:06','2026-03-13 13:09:24',NULL,NULL,NULL,'Recuerdos persistentes',0,1.00),
(3,1,'I','Recuerdos persistentes (último mes)','¿Ha tenido sueños de carácter recurrente sobre el acontecimiento, que le producen malestar?','yes_no','[{\"label\": \"Sí\", \"value\": 1}, {\"label\": \"No\", \"value\": 0}]',3,1,'2026-02-25 07:49:06','2026-03-13 13:09:28',NULL,NULL,NULL,'Recuerdos persistentes',0,1.00),
(4,1,'I','Evitación (último mes)','¿Se ha esforzado por evitar todo tipo de sentimientos, conversaciones o situaciones que le puedan recordar el acontecimiento?','yes_no','[{\"label\": \"Sí\", \"value\": 1}, {\"label\": \"No\", \"value\": 0}]',4,1,'2026-02-25 07:49:06','2026-03-13 13:09:33',NULL,NULL,NULL,'Evitación',0,1.00),
(5,1,'I','Evitación (último mes)','¿Se ha esforzado por evitar todo tipo de actividades, lugares o personas que motivan recuerdos del acontecimiento?','yes_no','[{\"label\": \"Sí\", \"value\": 1}, {\"label\": \"No\", \"value\": 0}]',5,1,'2026-02-25 07:49:06','2026-03-13 13:09:34',NULL,NULL,NULL,'Evitación',0,1.00),
(6,1,'I','Evitación (último mes)','¿Ha tenido dificultad para recordar alguna parte importante del evento?','yes_no','[{\"label\": \"Sí\", \"value\": 1}, {\"label\": \"No\", \"value\": 0}]',6,1,'2026-02-25 07:49:06','2026-03-13 13:09:35',NULL,NULL,NULL,'Evitación',0,1.00),
(7,1,'I','Evitación (último mes)','¿Ha disminuido su interés en sus actividades cotidianas?','yes_no','[{\"label\": \"Sí\", \"value\": 1}, {\"label\": \"No\", \"value\": 0}]',7,1,'2026-02-25 07:49:06','2026-03-13 13:09:36',NULL,NULL,NULL,'Evitación',0,1.00),
(8,1,'I','Evitación (último mes)','¿Se ha sentido usted alejado o distante de los demás?','yes_no','[{\"label\": \"Sí\", \"value\": 1}, {\"label\": \"No\", \"value\": 0}]',8,1,'2026-02-25 07:49:06','2026-03-13 13:09:36',NULL,NULL,NULL,'Evitación',0,1.00),
(9,1,'I','Evitación (último mes)','¿Ha notado que tiene dificultad para expresar sus sentimientos?','yes_no','[{\"label\": \"Sí\", \"value\": 1}, {\"label\": \"No\", \"value\": 0}]',9,1,'2026-02-25 07:49:06','2026-03-13 13:09:37',NULL,NULL,NULL,'Evitación',0,1.00),
(10,1,'I','Evitación (último mes)','¿Ha tenido la impresión de que su vida se va a acortar, que va a morir antes que otras personas o que tiene un futuro limitado?','yes_no','[{\"label\": \"Sí\", \"value\": 1}, {\"label\": \"No\", \"value\": 0}]',10,1,'2026-02-25 07:49:06','2026-03-13 13:09:38',NULL,NULL,NULL,'Evitación',0,1.00),
(11,1,'I','Afectación (último mes)','¿Ha tenido usted dificultades para dormir?','yes_no','[{\"label\": \"Sí\", \"value\": 1}, {\"label\": \"No\", \"value\": 0}]',11,1,'2026-02-25 07:49:06','2026-03-13 13:09:45',NULL,NULL,NULL,'Afectación',0,1.00),
(12,1,'I','Afectación (último mes)','¿Ha estado particularmente irritable o le han dado arranques de coraje?','yes_no','[{\"label\": \"Sí\", \"value\": 1}, {\"label\": \"No\", \"value\": 0}]',12,1,'2026-02-25 07:49:06','2026-03-13 13:09:45',NULL,NULL,NULL,'Afectación',0,1.00),
(13,1,'I','Afectación (último mes)','¿Ha tenido dificultad para concentrarse?','yes_no','[{\"label\": \"Sí\", \"value\": 1}, {\"label\": \"No\", \"value\": 0}]',13,1,'2026-02-25 07:49:06','2026-03-13 13:09:46',NULL,NULL,NULL,'Afectación',0,1.00),
(14,1,'I','Afectación (último mes)','¿Ha estado nervioso o constantemente en alerta?','yes_no','[{\"label\": \"Sí\", \"value\": 1}, {\"label\": \"No\", \"value\": 0}]',14,1,'2026-02-25 07:49:06','2026-03-13 13:09:47',NULL,NULL,NULL,'Afectación',0,1.00),
(15,1,'I','Afectación (último mes)','¿Se ha sobresaltado fácilmente por cualquier cosa?','yes_no','[{\"label\": \"Sí\", \"value\": 1}, {\"label\": \"No\", \"value\": 0}]',15,1,'2026-02-25 07:49:06','2026-03-13 13:09:47',NULL,NULL,NULL,'Afectación',0,1.00),
(16,2,'II','Condiciones de trabajo','Mi trabajo me exige hacer mucho esfuerzo físico','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',1,1,'2026-02-25 07:52:48','2026-03-13 12:43:53',NULL,NULL,'Condiciones de trabajo','Condiciones de trabajo',0,1.00),
(17,2,'II','Condiciones de trabajo','Me preocupa sufrir un accidente en mi trabajo','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',2,1,'2026-02-25 07:52:48','2026-03-13 12:43:53',NULL,NULL,'Condiciones de trabajo','Condiciones de trabajo',0,1.00),
(18,2,'II','Condiciones de trabajo','Considero que las actividades que realizo son peligrosas','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',3,1,'2026-02-25 07:52:48','2026-03-13 12:43:53',NULL,NULL,'Condiciones de trabajo','Condiciones de trabajo',0,1.00),
(19,2,'II','Carga de trabajo','Por la cantidad de trabajo que tengo debo quedarme tiempo adicional a mi turno','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',4,1,'2026-02-25 07:52:48','2026-03-13 12:43:53',NULL,NULL,'Carga de trabajo','Carga de trabajo',0,1.00),
(20,2,'II','Carga de trabajo','Por la cantidad de trabajo que tengo debo trabajar sin parar','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',5,1,'2026-02-25 07:52:48','2026-03-13 12:43:53',NULL,NULL,'Carga de trabajo','Carga de trabajo',0,1.00),
(21,2,'II','Carga de trabajo','Considero que es necesario mantener un ritmo de trabajo acelerado','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',6,1,'2026-02-25 07:52:48','2026-03-13 12:43:53',NULL,NULL,'Carga de trabajo','Carga de trabajo',0,1.00),
(22,2,'II','Carga mental','Mi trabajo exige que esté muy concentrado','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',7,1,'2026-02-25 07:52:48','2026-03-13 12:43:53',NULL,NULL,'Carga mental','Carga de trabajo',0,1.00),
(23,2,'II','Carga mental','Mi trabajo requiere que memorice mucha información','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',8,1,'2026-02-25 07:52:48','2026-03-13 12:43:53',NULL,NULL,'Carga mental','Carga de trabajo',0,1.00),
(24,2,'II','Carga mental','Mi trabajo exige que atienda varios asuntos al mismo tiempo','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',9,1,'2026-02-25 07:52:48','2026-03-13 12:43:53',NULL,NULL,'Carga mental','Carga de trabajo',0,1.00),
(25,2,'II','Alta responsabilidad','En mi trabajo soy responsable de cosas de mucho valor','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',10,1,'2026-02-25 07:52:48','2026-03-13 12:43:53',NULL,NULL,'Alta responsabilidad','Carga de trabajo',0,1.00),
(26,2,'II','Alta responsabilidad','Respondo ante mi jefe por los resultados de toda mi área de trabajo','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',11,1,'2026-02-25 07:52:48','2026-03-13 12:43:53',NULL,NULL,'Alta responsabilidad','Carga de trabajo',0,1.00),
(27,2,'II','Órdenes contradictorias','En mi trabajo me dan órdenes contradictorias','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',12,1,'2026-02-25 07:52:48','2026-03-13 12:43:53',NULL,NULL,'Órdenes contradictorias','Falta de control sobre el trabajo',0,1.00),
(28,2,'II','Órdenes contradictorias','Considero que en mi trabajo me piden hacer cosas innecesarias','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',13,1,'2026-02-25 07:52:48','2026-03-13 12:43:53',NULL,NULL,'Órdenes contradictorias','Falta de control sobre el trabajo',0,1.00),
(29,2,'II','Jornada','Trabajo horas extras más de tres veces a la semana','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',14,1,'2026-02-25 07:52:48','2026-03-13 12:43:53',NULL,NULL,'Jornada','Jornada de trabajo',0,1.00),
(30,2,'II','Jornada','Mi trabajo me exige laborar en días de descanso, festivos o fines de semana','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',15,1,'2026-02-25 07:52:48','2026-03-13 12:43:53',NULL,NULL,'Jornada','Jornada de trabajo',0,1.00),
(31,2,'II','Trabajo-familia','Considero que el tiempo en el trabajo es mucho y perjudica mis actividades familiares o personales','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',16,1,'2026-02-25 07:52:48','2026-03-13 12:43:53',NULL,NULL,'Trabajo-familia','Interferencia trabajo-familia',0,1.00),
(32,2,'II','Trabajo-familia','Pienso en las actividades familiares o personales cuando estoy en mi trabajo','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',17,1,'2026-02-25 07:52:48','2026-03-13 12:43:53',NULL,NULL,'Trabajo-familia','Interferencia trabajo-familia',0,1.00),
(33,2,'II','Control/Desarrollo','Mi trabajo permite que desarrolle nuevas habilidades','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',18,1,'2026-02-25 07:52:48','2026-03-13 12:43:53',NULL,NULL,'Control/Desarrollo','Falta de control sobre el trabajo',1,1.00),
(34,2,'II','Control/Desarrollo','En mi trabajo puedo aspirar a un mejor puesto','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',19,1,'2026-02-25 07:52:48','2026-03-13 12:43:53',NULL,NULL,'Control/Desarrollo','Falta de control sobre el trabajo',1,1.00),
(35,2,'II','Control/Autonomía','Durante mi jornada de trabajo puedo tomar pausas cuando las necesito','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',20,1,'2026-02-25 07:52:48','2026-03-13 12:43:53',NULL,NULL,'Control/Autonomía','Falta de control sobre el trabajo',1,1.00),
(36,2,'II','Control/Autonomía','Puedo decidir la velocidad a la que realizo mis actividades en mi trabajo','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',21,1,'2026-02-25 07:52:48','2026-03-13 12:43:53',NULL,NULL,'Control/Autonomía','Falta de control sobre el trabajo',1,1.00),
(37,2,'II','Control/Autonomía','Puedo cambiar el orden de las actividades que realizo en mi trabajo','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',22,1,'2026-02-25 07:52:48','2026-03-13 12:43:53',NULL,NULL,'Control/Autonomía','Falta de control sobre el trabajo',1,1.00),
(38,2,'II','Claridad/Información','Me informan con claridad cuáles son mis funciones','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',23,1,'2026-02-25 07:52:48','2026-03-13 12:43:53',NULL,NULL,'Claridad/Información','Falta de control sobre el trabajo',1,1.00),
(39,2,'II','Claridad/Información','Me explican claramente los resultados que debo obtener en mi trabajo','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',24,1,'2026-02-25 07:52:48','2026-03-13 12:43:53',NULL,NULL,'Claridad/Información','Falta de control sobre el trabajo',1,1.00),
(40,2,'II','Claridad/Información','Me informan con quién puedo resolver problemas o asuntos de trabajo','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',25,1,'2026-02-25 07:52:48','2026-03-13 12:43:53',NULL,NULL,'Claridad/Información','Falta de control sobre el trabajo',1,1.00),
(41,2,'II','Capacitación','Me permiten asistir a capacitaciones relacionadas con mi trabajo','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',26,1,'2026-02-25 07:52:48','2026-03-13 12:43:53',NULL,NULL,'Capacitación','Falta de control sobre el trabajo',1,1.00),
(42,2,'II','Capacitación','Recibo capacitación útil para hacer mi trabajo','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',27,1,'2026-02-25 07:52:48','2026-03-13 12:43:53',NULL,NULL,'Capacitación','Falta de control sobre el trabajo',1,1.00),
(43,2,'II','Relación con jefe','Mi jefe tiene en cuenta mis puntos de vista y opiniones','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',28,1,'2026-02-25 07:52:48','2026-03-13 12:43:53',NULL,NULL,'Relación con jefe','Liderazgo y relaciones en el trabajo',1,1.00),
(44,2,'II','Relación con jefe','Mi jefe ayuda a solucionar los problemas que se presentan en el trabajo','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',29,1,'2026-02-25 07:52:48','2026-03-13 12:43:53',NULL,NULL,'Relación con jefe','Liderazgo y relaciones en el trabajo',1,1.00),
(45,2,'II','Relación con compañeros','Puedo confiar en mis compañeros de trabajo','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',30,1,'2026-02-25 07:52:48','2026-03-13 12:43:53',NULL,NULL,'Relación con compañeros','Liderazgo y relaciones en el trabajo',1,1.00),
(46,2,'II','Relación con compañeros','Cuando tenemos que realizar trabajo de equipo los compañeros colaboran','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',31,1,'2026-02-25 07:52:48','2026-03-13 12:43:53',NULL,NULL,'Relación con compañeros','Liderazgo y relaciones en el trabajo',1,1.00),
(47,2,'II','Relación con compañeros','Mis compañeros de trabajo me ayudan cuando tengo dificultades','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',32,1,'2026-02-25 07:52:48','2026-03-13 12:43:53',NULL,NULL,'Relación con compañeros','Liderazgo y relaciones en el trabajo',1,1.00),
(48,2,'II','Violencia laboral','En mi trabajo puedo expresarme libremente sin interrupciones','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',33,1,'2026-02-25 07:52:48','2026-03-13 12:43:53',NULL,NULL,'Violencia laboral','Violencia',1,1.00),
(49,2,'II','Violencia laboral','Recibo críticas constantes a mi persona y/o trabajo','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',34,1,'2026-02-25 07:52:48','2026-03-13 12:43:53',NULL,NULL,'Violencia laboral','Violencia',0,1.00),
(50,2,'II','Violencia laboral','Recibo burlas, calumnias, difamaciones, humillaciones o ridiculizaciones','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',35,1,'2026-02-25 07:52:48','2026-03-13 12:43:53',NULL,NULL,'Violencia laboral','Violencia',0,1.00),
(51,2,'II','Violencia laboral','Se ignora mi presencia o se me excluye de las reuniones de trabajo y en la toma de decisiones','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',36,1,'2026-02-25 07:52:48','2026-03-13 12:43:53',NULL,NULL,'Violencia laboral','Violencia',0,1.00),
(52,2,'II','Violencia laboral','Se manipulan las situaciones de trabajo para hacerme parecer un mal trabajador','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',37,1,'2026-02-25 07:52:48','2026-03-13 12:43:53',NULL,NULL,'Violencia laboral','Violencia',0,1.00),
(53,2,'II','Violencia laboral','Se ignoran mis éxitos laborales y se atribuyen a otros trabajadores','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',38,1,'2026-02-25 07:52:48','2026-03-13 12:43:53',NULL,NULL,'Violencia laboral','Violencia',0,1.00),
(54,2,'II','Violencia laboral','Me bloquean o impiden las oportunidades que tengo para obtener ascenso o mejora en mi trabajo','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',39,1,'2026-02-25 07:52:48','2026-03-13 12:43:53',NULL,NULL,'Violencia laboral','Violencia',0,1.00),
(55,2,'II','Violencia laboral','He presenciado actos de violencia en mi centro de trabajo','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',40,1,'2026-02-25 07:52:48','2026-03-13 12:43:53',NULL,NULL,'Violencia laboral','Violencia',0,1.00),
(56,2,'II','Atención a clientes','Atiendo clientes o usuarios muy enojados','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',41,1,'2026-02-25 07:52:48','2026-03-13 12:43:53',NULL,NULL,'Atención a clientes','Carga de trabajo',0,1.00),
(57,2,'II','Atención a clientes','Mi trabajo me exige atender personas muy necesitadas de ayuda o enfermas','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',42,1,'2026-02-25 07:52:48','2026-03-13 12:43:53',NULL,NULL,'Atención a clientes','Carga de trabajo',0,1.00),
(58,2,'II','Atención a clientes','Para hacer mi trabajo debo demostrar sentimientos distintos a los míos','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',43,1,'2026-02-25 07:52:48','2026-03-13 12:43:53',NULL,NULL,'Atención a clientes','Carga de trabajo',0,1.00),
(59,2,'II','Jefatura','Comunican tarde los asuntos de trabajo','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',44,1,'2026-02-25 07:52:48','2026-03-13 12:43:53',NULL,NULL,'Jefatura','Liderazgo y relaciones en el trabajo',0,1.00),
(60,2,'II','Jefatura','Dificultan el logro de los resultados del trabajo','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',45,1,'2026-02-25 07:52:48','2026-03-13 12:43:53',NULL,NULL,'Jefatura','Liderazgo y relaciones en el trabajo',0,1.00),
(61,2,'II','Jefatura','Ignoran las sugerencias para mejorar su trabajo','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',46,1,'2026-02-25 07:52:48','2026-03-13 12:43:53',NULL,NULL,'Jefatura','Liderazgo y relaciones en el trabajo',0,1.00),
(62,3,'III','Ambiente de trabajo','El espacio donde trabajo me permite realizar mis actividades de manera segura e higiénica','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',1,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Ambiente de trabajo','Condiciones en el ambiente de trabajo',0,1.00),
(63,3,'III','Ambiente de trabajo','Mi trabajo me exige hacer mucho esfuerzo físico','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',2,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Ambiente de trabajo','Condiciones en el ambiente de trabajo',1,1.00),
(64,3,'III','Ambiente de trabajo','Me preocupa sufrir un accidente en mi trabajo','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',3,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Ambiente de trabajo','Condiciones en el ambiente de trabajo',1,1.00),
(65,3,'III','Ambiente de trabajo','Considero que en mi trabajo se aplican las normas de seguridad y salud en el trabajo','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',4,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Ambiente de trabajo','Condiciones en el ambiente de trabajo',0,1.00),
(66,3,'III','Ambiente de trabajo','Considero que las actividades que realizo son peligrosas','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',5,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Ambiente de trabajo','Condiciones en el ambiente de trabajo',1,1.00),
(67,3,'III','Carga de trabajo','Por la cantidad de trabajo que tengo debo quedarme tiempo adicional a mi turno','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',6,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Carga de trabajo','Carga de trabajo',1,1.00),
(68,3,'III','Carga de trabajo','Por la cantidad de trabajo que tengo debo trabajar sin parar','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',7,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Carga de trabajo','Carga de trabajo',1,1.00),
(69,3,'III','Carga de trabajo','Considero que es necesario mantener un ritmo de trabajo acelerado','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',8,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Carga de trabajo','Carga de trabajo',1,1.00),
(70,3,'III','Carga mental','Mi trabajo exige que esté muy concentrado','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',9,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Carga mental','Carga de trabajo',1,1.00),
(71,3,'III','Carga mental','Mi trabajo requiere que memorice mucha información','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',10,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Carga mental','Carga de trabajo',1,1.00),
(72,3,'III','Carga mental','En mi trabajo tengo que tomar decisiones difíciles muy rápido','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',11,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Carga mental','Carga de trabajo',1,1.00),
(73,3,'III','Carga mental','Mi trabajo exige que atienda varios asuntos al mismo tiempo','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',12,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Carga mental','Carga de trabajo',1,1.00),
(74,3,'III','Alta responsabilidad','En mi trabajo soy responsable de cosas de mucho valor','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',13,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Alta responsabilidad','Carga de trabajo',1,1.00),
(75,3,'III','Alta responsabilidad','Respondo ante mi jefe por los resultados de toda mi área de trabajo','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',14,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Alta responsabilidad','Carga de trabajo',1,1.00),
(76,3,'III','Órdenes contradictorias','En el trabajo me dan órdenes contradictorias','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',15,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Órdenes contradictorias','Falta de control sobre el trabajo',1,1.00),
(77,3,'III','Órdenes contradictorias','Considero que en mi trabajo me piden hacer cosas innecesarias','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',16,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Órdenes contradictorias','Falta de control sobre el trabajo',1,1.00),
(78,3,'III','Jornada','Trabajo horas extras más de tres veces a la semana','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',17,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Jornada','Jornada de trabajo',1,1.00),
(79,3,'III','Jornada','Mi trabajo me exige laborar en días de descanso, festivos o fines de semana','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',18,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Jornada','Jornada de trabajo',1,1.00),
(80,3,'III','Trabajo-familia','Considero que el tiempo en el trabajo es mucho y perjudica mis actividades familiares o personales','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',19,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Trabajo-familia','Interferencia trabajo-familia',1,1.00),
(81,3,'III','Trabajo-familia','Debo atender asuntos de trabajo cuando estoy en casa','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',20,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Trabajo-familia','Interferencia trabajo-familia',1,1.00),
(82,3,'III','Trabajo-familia','Pienso en las actividades familiares o personales cuando estoy en mi trabajo','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',21,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Trabajo-familia','Interferencia trabajo-familia',1,1.00),
(83,3,'III','Trabajo-familia','Pienso que mis responsabilidades familiares afectan mi trabajo','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',22,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Trabajo-familia','Interferencia trabajo-familia',1,1.00),
(84,3,'III','Desarrollo','Mi trabajo permite que desarrolle nuevas habilidades','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',23,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Desarrollo','Falta de control sobre el trabajo',0,1.00),
(85,3,'III','Desarrollo','En mi trabajo puedo aspirar a un mejor puesto','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',24,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Desarrollo','Falta de control sobre el trabajo',0,1.00),
(86,3,'III','Autonomía','Durante mi jornada de trabajo puedo tomar pausas cuando las necesito','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',25,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Autonomía','Falta de control sobre el trabajo',0,1.00),
(87,3,'III','Autonomía','Puedo decidir cuánto trabajo realizo durante la jornada laboral','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',26,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Autonomía','Falta de control sobre el trabajo',0,1.00),
(88,3,'III','Autonomía','Puedo decidir la velocidad a la que realizo mis actividades en mi trabajo','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',27,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Autonomía','Falta de control sobre el trabajo',0,1.00),
(89,3,'III','Autonomía','Puedo cambiar el orden de las actividades que realizo en mi trabajo','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',28,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Autonomía','Falta de control sobre el trabajo',0,1.00),
(90,3,'III','Cambio','Los cambios que se presentan en mi trabajo dificultan mi labor','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',29,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Cambio','Falta de control sobre el trabajo',1,1.00),
(91,3,'III','Cambio','Cuando se presentan cambios en mi trabajo se tienen en cuenta mis ideas o aportaciones','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',30,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Cambio','Falta de control sobre el trabajo',0,1.00),
(92,3,'III','Claridad/Información','Me informan con claridad cuáles son mis funciones','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',31,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Claridad/Información','Falta de control sobre el trabajo',0,1.00),
(93,3,'III','Claridad/Información','Me explican claramente los resultados que debo obtener en mi trabajo','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',32,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Claridad/Información','Falta de control sobre el trabajo',0,1.00),
(94,3,'III','Claridad/Información','Me explican claramente los objetivos de mi trabajo','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',33,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Claridad/Información','Falta de control sobre el trabajo',0,1.00),
(95,3,'III','Claridad/Información','Me informan con quién puedo resolver problemas o asuntos de trabajo','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',34,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Claridad/Información','Falta de control sobre el trabajo',0,1.00),
(96,3,'III','Capacitación','Me permiten asistir a capacitaciones relacionadas con mi trabajo','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',35,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Capacitación','Falta de control sobre el trabajo',0,1.00),
(97,3,'III','Capacitación','Recibo capacitación útil para hacer mi trabajo','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',36,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Capacitación','Falta de control sobre el trabajo',0,1.00),
(98,3,'III','Liderazgo','Mi jefe ayuda a organizar mejor el trabajo','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',37,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Liderazgo','Liderazgo y relaciones en el trabajo',0,1.00),
(99,3,'III','Liderazgo','Mi jefe tiene en cuenta mis puntos de vista y opiniones','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',38,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Liderazgo','Liderazgo y relaciones en el trabajo',0,1.00),
(100,3,'III','Liderazgo','Mi jefe me comunica a tiempo la información relacionada con el trabajo','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',39,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Liderazgo','Liderazgo y relaciones en el trabajo',0,1.00),
(101,3,'III','Liderazgo','La orientación que me da mi jefe me ayuda a realizar mejor mi trabajo','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',40,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Liderazgo','Liderazgo y relaciones en el trabajo',0,1.00),
(102,3,'III','Liderazgo','Mi jefe ayuda a solucionar los problemas que se presentan en el trabajo','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',41,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Liderazgo','Liderazgo y relaciones en el trabajo',0,1.00),
(103,3,'III','Relaciones','Puedo confiar en mis compañeros de trabajo','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',42,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Relaciones','Liderazgo y relaciones en el trabajo',0,1.00),
(104,3,'III','Relaciones','Entre compañeros solucionamos los problemas de trabajo de forma respetuosa','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',43,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Relaciones','Liderazgo y relaciones en el trabajo',0,1.00),
(105,3,'III','Relaciones','En mi trabajo me hacen sentir parte del grupo','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',44,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Relaciones','Liderazgo y relaciones en el trabajo',0,1.00),
(106,3,'III','Relaciones','Cuando tenemos que realizar trabajo de equipo los compañeros colaboran','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',45,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Relaciones','Liderazgo y relaciones en el trabajo',0,1.00),
(107,3,'III','Relaciones','Mis compañeros de trabajo me ayudan cuando tengo dificultades','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',46,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Relaciones','Liderazgo y relaciones en el trabajo',0,1.00),
(108,3,'III','Reconocimiento/Estabilidad','Me informan sobre lo que hago bien en mi trabajo','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',47,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Reconocimiento/Estabilidad','Reconocimiento del desempeño',0,1.00),
(109,3,'III','Reconocimiento/Estabilidad','La forma como evalúan mi trabajo en mi centro de trabajo me ayuda a mejorar mi desempeño','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',48,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Reconocimiento/Estabilidad','Reconocimiento del desempeño',0,1.00),
(110,3,'III','Reconocimiento/Estabilidad','En mi centro de trabajo me pagan a tiempo mi salario','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',49,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Reconocimiento/Estabilidad','Reconocimiento del desempeño',0,1.00),
(111,3,'III','Reconocimiento/Estabilidad','El pago que recibo es el que merezco por el trabajo que realizo','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',50,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Reconocimiento/Estabilidad','Reconocimiento del desempeño',0,1.00),
(112,3,'III','Reconocimiento/Estabilidad','Si obtengo los resultados esperados en mi trabajo me recompensan o reconocen','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',51,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Reconocimiento/Estabilidad','Reconocimiento del desempeño',0,1.00),
(113,3,'III','Reconocimiento/Estabilidad','Las personas que hacen bien el trabajo pueden crecer laboralmente','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',52,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Reconocimiento/Estabilidad','Reconocimiento del desempeño',0,1.00),
(114,3,'III','Reconocimiento/Estabilidad','Considero que mi trabajo es estable','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',53,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Reconocimiento/Estabilidad','Insuficiente sentido de pertenencia e inestabilidad',0,1.00),
(115,3,'III','Reconocimiento/Estabilidad','En mi trabajo existe continua rotación de personal','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',54,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Reconocimiento/Estabilidad','Insuficiente sentido de pertenencia e inestabilidad',1,1.00),
(117,3,'III','Reconocimiento/Estabilidad','Siento orgullo de laborar en este centro de trabajo','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',55,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Reconocimiento/Estabilidad','Insuficiente sentido de pertenencia e inestabilidad',0,1.00),
(118,3,'III','Reconocimiento/Estabilidad','Me siento comprometido con mi trabajo','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',56,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Reconocimiento/Estabilidad','Insuficiente sentido de pertenencia e inestabilidad',0,1.00),
(119,3,'III','Violencia laboral','En mi trabajo puedo expresarme libremente sin interrupciones','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',57,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Violencia laboral','Violencia',0,1.00),
(120,3,'III','Violencia laboral','Recibo críticas constantes a mi persona y/o trabajo','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',58,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Violencia laboral','Violencia',1,1.00),
(121,3,'III','Violencia laboral','Recibo burlas, calumnias, difamaciones, humillaciones o ridiculizaciones','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',59,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Violencia laboral','Violencia',1,1.00),
(122,3,'III','Violencia laboral','Se ignora mi presencia o se me excluye de las reuniones de trabajo y en la toma de decisiones','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',60,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Violencia laboral','Violencia',1,1.00),
(123,3,'III','Violencia laboral','Se manipulan las situaciones de trabajo para hacerme parecer un mal trabajador','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',61,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Violencia laboral','Violencia',1,1.00),
(124,3,'III','Violencia laboral','Se ignoran mis éxitos laborales y se atribuyen a otros trabajadores','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',62,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Violencia laboral','Violencia',1,1.00),
(125,3,'III','Violencia laboral','Me bloquean o impiden las oportunidades que tengo para obtener ascenso o mejora en mi trabajo','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',63,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Violencia laboral','Violencia',1,1.00),
(126,3,'III','Violencia laboral','He presenciado actos de violencia en mi centro de trabajo','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',64,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Violencia laboral','Violencia',1,1.00),
(127,3,'III','Atención a clientes','Atiendo clientes o usuarios muy enojados','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',65,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Atención a clientes','Carga de trabajo',1,1.00),
(128,3,'III','Atención a clientes','Mi trabajo me exige atender personas muy necesitadas de ayuda o enfermas','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',66,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Atención a clientes','Carga de trabajo',1,1.00),
(129,3,'III','Atención a clientes','Para hacer mi trabajo debo demostrar sentimientos distintos a los míos','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',67,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Atención a clientes','Carga de trabajo',1,1.00),
(130,3,'III','Atención a clientes','Mi trabajo me exige atender situaciones de violencia','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',68,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Atención a clientes','Carga de trabajo',1,1.00),
(131,3,'III','Jefatura','Comunican tarde los asuntos de trabajo','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',69,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Jefatura','Liderazgo y relaciones en el trabajo',1,1.00),
(132,3,'III','Jefatura','Dificultan el logro de los resultados del trabajo','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',70,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Jefatura','Liderazgo y relaciones en el trabajo',1,1.00),
(133,3,'III','Jefatura','Cooperan poco cuando se necesita','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',71,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Jefatura','Liderazgo y relaciones en el trabajo',1,1.00),
(134,3,'III','Jefatura','Ignoran las sugerencias para mejorar su trabajo','likert','[{\"label\": \"Siempre\", \"value\": 4}, {\"label\": \"Casi siempre\", \"value\": 3}, {\"label\": \"Algunas veces\", \"value\": 2}, {\"label\": \"Casi nunca\", \"value\": 1}, {\"label\": \"Nunca\", \"value\": 0}]',72,1,'2026-02-25 08:06:05','2026-03-13 12:43:53',NULL,NULL,'Jefatura','Liderazgo y relaciones en el trabajo',1,1.00),
(188,75,'V','Metadatos','Número de cuestionario','open',NULL,1,1,'2026-02-25 09:15:06','2026-03-13 13:10:39',NULL,NULL,NULL,'Información del trabajador',0,0.00),
(189,75,'V','Metadatos','Fecha de aplicación','open',NULL,2,1,'2026-02-25 09:15:06','2026-03-13 13:10:38',NULL,NULL,NULL,'Información del trabajador',0,0.00),
(190,75,'V','Información del trabajador','Sexo','multiple','[{\"label\": \"Masculino\", \"value\": \"M\"}, {\"label\": \"Femenino\", \"value\": \"F\"}]',3,1,'2026-02-25 09:15:06','2026-03-13 13:10:40',NULL,NULL,NULL,'Información del trabajador',0,0.00),
(191,75,'V','Información del trabajador','Edad (rango)','multiple','[{\"label\": \"15 – 19\", \"value\": \"15-19\"}, {\"label\": \"20 – 24\", \"value\": \"20-24\"}, {\"label\": \"25 – 29\", \"value\": \"25-29\"}, {\"label\": \"30 – 34\", \"value\": \"30-34\"}, {\"label\": \"35 – 39\", \"value\": \"35-39\"}, {\"label\": \"40 – 44\", \"value\": \"40-44\"}, {\"label\": \"45 – 49\", \"value\": \"45-49\"}, {\"label\": \"50 – 54\", \"value\": \"50-54\"}, {\"label\": \"55 – 59\", \"value\": \"55-59\"}, {\"label\": \"60 – 64\", \"value\": \"60-64\"}, {\"label\": \"65 – 69\", \"value\": \"65-69\"}, {\"label\": \"70 o más\", \"value\": \"70+\"}]',4,1,'2026-02-25 09:15:06','2026-03-13 13:10:41',NULL,NULL,NULL,'Información del trabajador',0,0.00),
(192,75,'V','Información del trabajador','Estado civil','multiple','[{\"label\": \"Casado\", \"value\": \"casado\"}, {\"label\": \"Divorciado\", \"value\": \"divorciado\"}, {\"label\": \"Soltero\", \"value\": \"soltero\"}, {\"label\": \"Viudo\", \"value\": \"viudo\"}, {\"label\": \"Unión libre\", \"value\": \"union_libre\"}]',5,1,'2026-02-25 09:15:06','2026-03-13 13:10:41',NULL,NULL,NULL,'Información del trabajador',0,0.00),
(193,75,'V','Información del trabajador','Nivel de estudios','multiple','[{\"label\": \"Sin formación\", \"value\": \"sin_formacion\"}, {\"label\": \"Primaria terminada\", \"value\": \"primaria_terminada\"}, {\"label\": \"Primaria incompleta\", \"value\": \"primaria_incompleta\"}, {\"label\": \"Secundaria terminada\", \"value\": \"secundaria_terminada\"}, {\"label\": \"Secundaria incompleta\", \"value\": \"secundaria_incompleta\"}, {\"label\": \"Preparatoria/Bachillerato terminado\", \"value\": \"bachillerato_terminado\"}, {\"label\": \"Preparatoria/Bachillerato incompleto\", \"value\": \"bachillerato_incompleto\"}, {\"label\": \"Técnico Superior terminado\", \"value\": \"tecnico_terminado\"}, {\"label\": \"Técnico Superior incompleto\", \"value\": \"tecnico_incompleto\"}, {\"label\": \"Licenciatura terminada\", \"value\": \"licenciatura_terminada\"}, {\"label\": \"Licenciatura incompleta\", \"value\": \"licenciatura_incompleta\"}, {\"label\": \"Maestría terminada\", \"value\": \"maestria_terminada\"}, {\"label\": \"Maestría incompleta\", \"value\": \"maestria_incompleta\"}, {\"label\": \"Doctorado terminado\", \"value\": \"doctorado_terminado\"}, {\"label\": \"Doctorado incompleto\", \"value\": \"doctorado_incompleto\"}]',6,1,'2026-02-25 09:15:06','2026-03-13 13:10:42',NULL,NULL,NULL,'Información del trabajador',0,0.00),
(194,75,'V','Datos laborales','Ocupación / profesión / puesto','open',NULL,7,1,'2026-02-25 09:15:06','2026-03-13 13:10:42',NULL,NULL,NULL,'Información del trabajador',0,0.00),
(195,75,'V','Datos laborales','Departamento / Sección / Área','open',NULL,8,1,'2026-02-25 09:15:06','2026-03-13 13:10:42',NULL,NULL,NULL,'Información del trabajador',0,0.00),
(196,75,'V','Datos laborales','Tipo de puesto','multiple','[{\"label\": \"Operativo\", \"value\": \"operativo\"}, {\"label\": \"Supervisor\", \"value\": \"supervisor\"}, {\"label\": \"Profesional o técnico\", \"value\": \"profesional_tecnico\"}, {\"label\": \"Gerente\", \"value\": \"gerente\"}]',9,1,'2026-02-25 09:15:06','2026-03-13 13:11:04',NULL,NULL,NULL,'Información del trabajador',0,0.00),
(197,75,'V','Datos laborales','Tipo de contratación','multiple','[{\"label\": \"Por obra o proyecto\", \"value\": \"obra_proyecto\"}, {\"label\": \"Tiempo indeterminado\", \"value\": \"indeterminado\"}, {\"label\": \"Por tiempo determinado (temporal)\", \"value\": \"temporal\"}, {\"label\": \"Honorarios\", \"value\": \"honorarios\"}]',10,1,'2026-02-25 09:15:06','2026-03-13 13:10:58',NULL,NULL,NULL,'Información del trabajador',0,0.00),
(198,75,'V','Datos laborales','Tipo de personal','multiple','[{\"label\": \"Sindicalizado\", \"value\": \"sindicalizado\"}, {\"label\": \"Confianza\", \"value\": \"confianza\"}, {\"label\": \"Ninguno\", \"value\": \"ninguno\"}]',11,1,'2026-02-25 09:15:06','2026-03-13 13:10:57',NULL,NULL,NULL,'Información del trabajador',0,0.00),
(199,75,'V','Datos laborales','Tipo de jornada de trabajo','multiple','[{\"label\": \"Fijo nocturno (entre 20:00 y 6:00 hrs)\", \"value\": \"fijo_nocturno\"}, {\"label\": \"Fijo mixto (combinación nocturno y diurno)\", \"value\": \"fijo_mixto\"}, {\"label\": \"Fijo diurno (entre 6:00 y 20:00 hrs)\", \"value\": \"fijo_diurno\"}]',12,1,'2026-02-25 09:15:06','2026-03-13 13:10:56',NULL,NULL,NULL,'Información del trabajador',0,0.00),
(200,75,'V','Datos laborales','Realiza rotación de turnos','multiple','[{\"label\": \"Sí\", \"value\": \"si\"}, {\"label\": \"No\", \"value\": \"no\"}]',13,1,'2026-02-25 09:15:06','2026-03-13 13:10:56',NULL,NULL,NULL,'Información del trabajador',0,0.00),
(201,75,'V','Datos laborales','Tiempo en el puesto actual','multiple','[{\"label\": \"Menos de 6 meses\", \"value\": \"<6m\"}, {\"label\": \"Entre 6 meses y 1 año\", \"value\": \"6m-1a\"}, {\"label\": \"Entre 1 a 4 años\", \"value\": \"1-4a\"}, {\"label\": \"Entre 5 a 9 años\", \"value\": \"5-9a\"}, {\"label\": \"Entre 10 a 14 años\", \"value\": \"10-14a\"}, {\"label\": \"Entre 15 a 19 años\", \"value\": \"15-19a\"}, {\"label\": \"Entre 20 a 24 años\", \"value\": \"20-24a\"}, {\"label\": \"25 años o más\", \"value\": \"25a+\"}]',14,1,'2026-02-25 09:15:06','2026-03-13 13:10:55',NULL,NULL,NULL,'Información del trabajador',0,0.00),
(202,75,'V','Datos laborales','Tiempo de experiencia laboral','multiple','[{\"label\": \"Menos de 6 meses\", \"value\": \"<6m\"}, {\"label\": \"Entre 6 meses y 1 año\", \"value\": \"6m-1a\"}, {\"label\": \"Entre 1 a 4 años\", \"value\": \"1-4a\"}, {\"label\": \"Entre 5 a 9 años\", \"value\": \"5-9a\"}, {\"label\": \"Entre 10 a 14 años\", \"value\": \"10-14a\"}, {\"label\": \"Entre 15 a 19 años\", \"value\": \"15-19a\"}, {\"label\": \"Entre 20 a 24 años\", \"value\": \"20-24a\"}, {\"label\": \"25 años o más\", \"value\": \"25a+\"}]',15,1,'2026-02-25 09:15:06','2026-03-13 13:10:55',NULL,NULL,NULL,'Información del trabajador',0,0.00),
(203,74,'IV','Politica','Prevencion de Riesgos Psicosociales','likert',NULL,1,1,'2026-02-26 07:50:56','2026-03-13 13:10:52',NULL,NULL,NULL,'',0,0.00);

/*Table structure for table `nom035_scoring_rules` */

DROP TABLE IF EXISTS `nom035_scoring_rules`;

CREATE TABLE `nom035_scoring_rules` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `guide` enum('II','III') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `rule_json` json NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_nom035_scoring_rules_guide` (`guide`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/*Data for the table `nom035_scoring_rules` */

insert  into `nom035_scoring_rules`(`id`,`guide`,`rule_json`,`created_at`,`updated_at`) values 
(2,'III','{\"final\": [{\"max\": 49, \"min\": 0, \"risk\": \"Nulo o despreciable\"}, {\"max\": 74, \"min\": 50, \"risk\": \"Bajo\"}, {\"max\": 98, \"min\": 75, \"risk\": \"Medio\"}, {\"max\": 139, \"min\": 99, \"risk\": \"Alto\"}, {\"max\": 999999, \"min\": 140, \"risk\": \"Muy alto\"}]}','2026-02-25 08:21:55','2026-02-25 08:21:55');

/*Table structure for table `nom035_section_questions` */

DROP TABLE IF EXISTS `nom035_section_questions`;

CREATE TABLE `nom035_section_questions` (
  `section_id` bigint unsigned NOT NULL,
  `question_id` bigint unsigned NOT NULL,
  `order_no` int NOT NULL DEFAULT '0',
  `required` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`section_id`,`question_id`),
  KEY `idx_nom035_sq_section_order` (`section_id`,`order_no`),
  KEY `idx_nom035_sq_question` (`question_id`),
  CONSTRAINT `fk_nom035_sq_question` FOREIGN KEY (`question_id`) REFERENCES `nom035_questions` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_nom035_sq_section` FOREIGN KEY (`section_id`) REFERENCES `nom035_sections` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/*Data for the table `nom035_section_questions` */

insert  into `nom035_section_questions`(`section_id`,`question_id`,`order_no`,`required`,`created_at`) values 
(29,16,1,1,'2026-02-25 08:38:55'),
(30,17,2,1,'2026-02-25 08:38:55'),
(31,18,3,1,'2026-02-25 08:38:55'),
(32,19,4,1,'2026-02-25 08:38:55'),
(32,24,9,1,'2026-02-25 08:38:55'),
(33,20,5,1,'2026-02-25 08:38:55'),
(33,21,6,1,'2026-02-25 08:38:55'),
(34,22,7,1,'2026-02-25 08:38:55'),
(34,23,8,1,'2026-02-25 08:38:55'),
(35,25,10,1,'2026-02-25 08:38:55'),
(35,26,11,1,'2026-02-25 08:38:55'),
(36,27,12,1,'2026-02-25 08:38:55'),
(36,28,13,1,'2026-02-25 08:38:55'),
(37,33,18,1,'2026-02-25 08:38:55'),
(37,34,19,1,'2026-02-25 08:38:55'),
(38,35,20,1,'2026-02-25 08:38:55'),
(38,36,21,1,'2026-02-25 08:38:55'),
(38,37,22,1,'2026-02-25 08:38:55'),
(39,41,26,1,'2026-02-25 08:38:55'),
(39,42,27,1,'2026-02-25 08:38:55'),
(40,29,14,1,'2026-02-25 08:38:55'),
(40,30,15,1,'2026-02-25 08:38:55'),
(41,31,16,1,'2026-02-25 08:38:55'),
(42,32,17,1,'2026-02-25 08:38:55'),
(43,38,23,1,'2026-02-25 08:38:55'),
(43,39,24,1,'2026-02-25 08:38:55'),
(43,40,25,1,'2026-02-25 08:38:55'),
(44,43,28,1,'2026-02-25 08:38:55'),
(44,44,29,1,'2026-02-25 08:38:55'),
(45,45,30,1,'2026-02-25 08:38:55'),
(45,46,31,1,'2026-02-25 08:38:55'),
(45,47,32,1,'2026-02-25 08:38:55'),
(46,48,33,1,'2026-02-25 08:38:55'),
(46,49,34,1,'2026-02-25 08:38:55'),
(46,50,35,1,'2026-02-25 08:38:55'),
(46,51,36,1,'2026-02-25 08:38:55'),
(46,52,37,1,'2026-02-25 08:38:55'),
(46,53,38,1,'2026-02-25 08:38:55'),
(46,54,39,1,'2026-02-25 08:38:55'),
(46,55,40,1,'2026-02-25 08:38:55'),
(47,56,41,0,'2026-02-25 08:38:55'),
(47,57,42,0,'2026-02-25 08:38:55'),
(47,58,43,0,'2026-02-25 08:38:55'),
(48,59,44,0,'2026-02-25 08:38:55'),
(48,60,45,0,'2026-02-25 08:38:55'),
(48,61,46,0,'2026-02-25 08:38:55'),
(49,62,1,1,'2026-02-25 08:38:55'),
(49,64,3,1,'2026-02-25 08:38:55'),
(50,63,2,1,'2026-02-25 08:38:55'),
(50,65,4,1,'2026-02-25 08:38:55'),
(51,66,5,1,'2026-02-25 08:38:55'),
(52,67,6,1,'2026-02-25 08:38:55'),
(52,73,12,1,'2026-02-25 08:38:55'),
(53,68,7,1,'2026-02-25 08:38:55'),
(53,69,8,1,'2026-02-25 08:38:55'),
(54,70,9,1,'2026-02-25 08:38:55'),
(54,71,10,1,'2026-02-25 08:38:55'),
(54,72,11,1,'2026-02-25 08:38:55'),
(55,74,13,1,'2026-02-25 08:38:55'),
(55,75,14,1,'2026-02-25 08:38:55'),
(56,76,15,1,'2026-02-25 08:38:55'),
(56,77,16,1,'2026-02-25 08:38:55'),
(57,86,25,1,'2026-02-25 08:38:55'),
(57,87,26,1,'2026-02-25 08:38:55'),
(57,88,27,1,'2026-02-25 08:38:55'),
(57,89,28,1,'2026-02-25 08:38:55'),
(58,84,23,1,'2026-02-25 08:38:55'),
(58,85,24,1,'2026-02-25 08:38:55'),
(59,90,29,1,'2026-02-25 08:38:55'),
(59,91,30,1,'2026-02-25 08:38:55'),
(60,96,35,1,'2026-02-25 08:38:55'),
(60,97,36,1,'2026-02-25 08:38:55'),
(61,78,17,1,'2026-02-25 08:38:55'),
(61,79,18,1,'2026-02-25 08:38:55'),
(62,80,19,1,'2026-02-25 08:38:55'),
(62,81,20,1,'2026-02-25 08:38:55'),
(63,82,21,1,'2026-02-25 08:38:55'),
(63,83,22,1,'2026-02-25 08:38:55'),
(64,92,31,1,'2026-02-25 08:38:55'),
(64,93,32,1,'2026-02-25 08:38:55'),
(64,94,33,1,'2026-02-25 08:38:55'),
(64,95,34,1,'2026-02-25 08:38:55'),
(65,98,37,1,'2026-02-25 08:38:55'),
(65,99,38,1,'2026-02-25 08:38:55'),
(65,100,39,1,'2026-02-25 08:38:55'),
(65,101,40,1,'2026-02-25 08:38:55'),
(65,102,41,1,'2026-02-25 08:38:55'),
(66,103,42,1,'2026-02-25 08:38:55'),
(66,104,43,1,'2026-02-25 08:38:55'),
(66,105,44,1,'2026-02-25 08:38:55'),
(66,106,45,1,'2026-02-25 08:38:55'),
(66,107,46,1,'2026-02-25 08:38:55'),
(67,119,57,1,'2026-02-25 08:38:55'),
(67,120,58,1,'2026-02-25 08:38:55'),
(67,121,59,1,'2026-02-25 08:38:55'),
(67,122,60,1,'2026-02-25 08:38:55'),
(67,123,61,1,'2026-02-25 08:38:55'),
(67,124,62,1,'2026-02-25 08:38:55'),
(67,125,63,1,'2026-02-25 08:38:55'),
(67,126,64,1,'2026-02-25 08:38:55'),
(68,108,47,1,'2026-02-25 08:38:55'),
(68,109,48,1,'2026-02-25 08:38:55'),
(69,110,49,1,'2026-02-25 08:38:55'),
(69,111,50,1,'2026-02-25 08:38:55'),
(69,112,51,1,'2026-02-25 08:38:55'),
(69,113,52,1,'2026-02-25 08:38:55'),
(70,114,53,1,'2026-02-25 08:38:55'),
(70,115,54,1,'2026-02-25 08:38:55'),
(71,117,55,1,'2026-02-25 08:38:55'),
(71,118,56,1,'2026-02-25 08:38:55'),
(72,127,65,0,'2026-02-25 08:38:55'),
(72,128,66,0,'2026-02-25 08:38:55'),
(72,129,67,0,'2026-02-25 08:38:55'),
(72,130,68,0,'2026-02-25 08:38:55'),
(73,131,69,0,'2026-02-25 08:38:55'),
(73,132,70,0,'2026-02-25 08:38:55'),
(73,133,71,0,'2026-02-25 08:38:55'),
(73,134,72,0,'2026-02-25 08:38:55');

/*Table structure for table `nom035_sections` */

DROP TABLE IF EXISTS `nom035_sections`;

CREATE TABLE `nom035_sections` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `title` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `instructions` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `order_no` int NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_nom035_sections_active_order` (`is_active`,`order_no`)
) ENGINE=InnoDB AUTO_INCREMENT=77 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/*Data for the table `nom035_sections` */

insert  into `nom035_sections`(`id`,`title`,`description`,`instructions`,`order_no`,`is_active`,`created_at`,`updated_at`) values 
(1,'Guía I - Acontecimientos traumáticos severos','Cuestionario Guía de Referencia I','Responde con honestidad. No hay respuestas correctas o incorrectas.',10,1,'2026-02-25 07:48:02','2026-02-25 07:48:15'),
(2,'Guía II - Factores de riesgo psicosocial','Cuestionario Guía de Referencia II (46 ítems)','Considere las condiciones de los últimos dos meses.',20,1,'2026-02-25 07:48:02','2026-02-25 07:48:16'),
(3,'Guía III - FRPS y Entorno Organizacional','Cuestionario Guía de Referencia III (72 ítems)','Considere las condiciones de los últimos dos meses.',30,1,'2026-02-25 07:48:02','2026-02-25 07:48:23'),
(11,'Guía II · Ambiente de trabajo (Ítems 1–3)','Bloque 1 del cuestionario','Responde considerando los últimos dos meses.',2101,1,'2026-02-25 08:29:50','2026-02-25 08:29:50'),
(12,'Guía II · Factores propios de la actividad (Ítems 4–13)','Bloque 2 del cuestionario','Responde considerando los últimos dos meses.',2102,1,'2026-02-25 08:29:50','2026-02-25 08:29:50'),
(13,'Guía II · Organización del tiempo de trabajo (Ítems 14–17)','Bloque 3 del cuestionario','Responde considerando los últimos dos meses.',2103,1,'2026-02-25 08:29:50','2026-02-25 08:29:50'),
(14,'Guía II · Falta de control sobre el trabajo (Ítems 18–22, 26–27)','Bloque 4 del cuestionario','Responde considerando los últimos dos meses.',2104,1,'2026-02-25 08:29:50','2026-02-25 08:29:50'),
(15,'Guía II · Liderazgo y relaciones (Ítems 23–25, 28–32)','Bloque 5 del cuestionario','Responde considerando los últimos dos meses.',2105,1,'2026-02-25 08:29:50','2026-02-25 08:29:50'),
(16,'Guía II · Violencia laboral (Ítems 33–40)','Bloque 6 del cuestionario','Responde considerando los últimos dos meses.',2106,1,'2026-02-25 08:29:50','2026-02-25 08:29:50'),
(17,'Guía II · Atención a clientes y usuarios (Ítems 41–43) [CONDICIONAL]','Bloque condicional del PDF','Si respondiste \"SÍ\" a servicio a clientes/usuarios, responde este bloque.',2107,1,'2026-02-25 08:29:50','2026-02-25 08:29:50'),
(18,'Guía II · Jefatura: trabajadores que supervisa (Ítems 44–46) [CONDICIONAL]','Bloque condicional del PDF','Si respondiste \"SÍ\" a \"Soy jefe\", responde este bloque.',2108,1,'2026-02-25 08:29:50','2026-02-25 08:29:50'),
(19,'Guía III · Ambiente de trabajo (Ítems 1–5)','Bloque del PDF','Responde considerando los últimos dos meses.',3101,1,'2026-02-25 08:31:08','2026-02-25 08:31:08'),
(20,'Guía III · Factores propios de la actividad (Ítems 6–16)','Bloque del PDF','Responde considerando los últimos dos meses.',3102,1,'2026-02-25 08:31:08','2026-02-25 08:31:08'),
(21,'Guía III · Organización del tiempo de trabajo (Ítems 17–22)','Bloque del PDF','Responde considerando los últimos dos meses.',3103,1,'2026-02-25 08:31:08','2026-02-25 08:31:08'),
(22,'Guía III · Falta de control sobre el trabajo (Ítems 23–30)','Bloque del PDF','Responde considerando los últimos dos meses.',3104,1,'2026-02-25 08:31:08','2026-02-25 08:31:08'),
(23,'Guía III · Liderazgo (Ítems 31–41)','Bloque del PDF','Responde considerando los últimos dos meses.',3105,1,'2026-02-25 08:31:08','2026-02-25 08:31:08'),
(24,'Guía III · Relaciones en el trabajo (Ítems 42–46)','Bloque del PDF','Responde considerando los últimos dos meses.',3106,1,'2026-02-25 08:31:08','2026-02-25 08:31:08'),
(25,'Guía III · Entorno organizacional (Ítems 47–56)','Bloque del PDF','Responde considerando los últimos dos meses.',3107,1,'2026-02-25 08:31:08','2026-02-25 08:31:08'),
(26,'Guía III · Violencia laboral (Ítems 57–64)','Bloque del PDF','Responde considerando los últimos dos meses.',3108,1,'2026-02-25 08:31:08','2026-02-25 08:31:08'),
(27,'Guía III · Atención a clientes y usuarios (Ítems 65–68) [CONDICIONAL]','Bloque condicional del PDF','Si respondiste \"SÍ\" a servicio a clientes/usuarios, responde este bloque.',3109,1,'2026-02-25 08:31:08','2026-02-25 08:31:08'),
(28,'Guía III · Jefatura: personas que supervisa (Ítems 69–72) [CONDICIONAL]','Bloque condicional del PDF','Si respondiste \"SÍ\" a \"Soy jefe\", responde este bloque.',3110,1,'2026-02-25 08:31:08','2026-02-25 08:31:08'),
(29,'GII · Ambiente de trabajo / Condiciones en el ambiente / Condiciones deficientes e insalubres (Ítem 1)','Tabla 3 (Guía II) — Dominio: Condiciones en el ambiente de trabajo','Considere los últimos 2 meses.',2201,1,'2026-02-25 08:38:55','2026-02-25 08:38:55'),
(30,'GII · Ambiente de trabajo / Condiciones en el ambiente / Condiciones peligrosas e inseguras (Ítem 2)','Tabla 3 (Guía II) — Dominio: Condiciones en el ambiente de trabajo','Considere los últimos 2 meses.',2202,1,'2026-02-25 08:38:55','2026-02-25 08:38:55'),
(31,'GII · Ambiente de trabajo / Condiciones en el ambiente / Trabajos peligrosos (Ítem 3)','Tabla 3 (Guía II) — Dominio: Condiciones en el ambiente de trabajo','Considere los últimos 2 meses.',2203,1,'2026-02-25 08:38:55','2026-02-25 08:38:55'),
(32,'GII · Factores propios / Carga de trabajo / Cargas cuantitativas (Ítems 4,9)','Tabla 3 (Guía II) — Dominio: Carga de trabajo','Considere los últimos 2 meses.',2204,1,'2026-02-25 08:38:55','2026-02-25 08:38:55'),
(33,'GII · Factores propios / Carga de trabajo / Ritmos de trabajo acelerado (Ítems 5,6)','Tabla 3 (Guía II) — Dominio: Carga de trabajo','Considere los últimos 2 meses.',2205,1,'2026-02-25 08:38:55','2026-02-25 08:38:55'),
(34,'GII · Factores propios / Carga de trabajo / Carga mental (Ítems 7,8)','Tabla 3 (Guía II) — Dominio: Carga de trabajo','Considere los últimos 2 meses.',2206,1,'2026-02-25 08:38:55','2026-02-25 08:38:55'),
(35,'GII · Factores propios / Carga de trabajo / Cargas de alta responsabilidad (Ítems 10,11)','Tabla 3 (Guía II) — Dominio: Carga de trabajo','Considere los últimos 2 meses.',2207,1,'2026-02-25 08:38:55','2026-02-25 08:38:55'),
(36,'GII · Factores propios / Carga de trabajo / Cargas contradictorias o inconsistentes (Ítems 12,13)','Tabla 3 (Guía II) — Dominio: Carga de trabajo','Considere los últimos 2 meses.',2208,1,'2026-02-25 08:38:55','2026-02-25 08:38:55'),
(37,'GII · Falta de control / Falta de control / Limitada o nula posibilidad de desarrollo (Ítems 18,19)','Tabla 3 (Guía II) — Dominio: Falta de control sobre el trabajo','Considere los últimos 2 meses.',2209,1,'2026-02-25 08:38:55','2026-02-25 08:38:55'),
(38,'GII · Falta de control / Falta de control / Falta de control y autonomía (Ítems 20,21,22)','Tabla 3 (Guía II) — Dominio: Falta de control sobre el trabajo','Considere los últimos 2 meses.',2210,1,'2026-02-25 08:38:55','2026-02-25 08:38:55'),
(39,'GII · Falta de control / Falta de control / Limitada o inexistente capacitación (Ítems 26,27)','Tabla 3 (Guía II) — Dominio: Falta de control sobre el trabajo','Considere los últimos 2 meses.',2211,1,'2026-02-25 08:38:55','2026-02-25 08:38:55'),
(40,'GII · Organización del tiempo / Jornada / Jornadas extensas (Ítems 14,15)','Tabla 3 (Guía II) — Dominio: Jornada de trabajo','Considere los últimos 2 meses.',2212,1,'2026-02-25 08:38:55','2026-02-25 08:38:55'),
(41,'GII · Organización del tiempo / Trabajo-familia / Influencia fuera del centro (Ítem 16)','Tabla 3 (Guía II) — Dominio: Interferencia trabajo-familia','Considere los últimos 2 meses.',2213,1,'2026-02-25 08:38:55','2026-02-25 08:38:55'),
(42,'GII · Organización del tiempo / Trabajo-familia / Influencia responsabilidades familiares (Ítem 17)','Tabla 3 (Guía II) — Dominio: Interferencia trabajo-familia','Considere los últimos 2 meses.',2214,1,'2026-02-25 08:38:55','2026-02-25 08:38:55'),
(43,'GII · Liderazgo y relaciones / Liderazgo / Escasa claridad de funciones (Ítems 23,24,25)','Tabla 3 (Guía II) — Dominio: Liderazgo','Considere los últimos 2 meses.',2215,1,'2026-02-25 08:38:55','2026-02-25 08:38:55'),
(44,'GII · Liderazgo y relaciones / Liderazgo / Características del liderazgo (Ítems 28,29)','Tabla 3 (Guía II) — Dominio: Liderazgo','Considere los últimos 2 meses.',2216,1,'2026-02-25 08:38:55','2026-02-25 08:38:55'),
(45,'GII · Liderazgo y relaciones / Relaciones / Relaciones sociales en el trabajo (Ítems 30,31,32)','Tabla 3 (Guía II) — Dominio: Relaciones en el trabajo','Considere los últimos 2 meses.',2217,1,'2026-02-25 08:38:55','2026-02-25 08:38:55'),
(46,'GII · Violencia / Violencia / Violencia laboral (Ítems 33–40)','Tabla 3 (Guía II) — Dominio: Violencia','Considere los últimos 2 meses.',2218,1,'2026-02-25 08:38:55','2026-02-25 08:38:55'),
(47,'GII · Factores propios / Carga de trabajo / Cargas psicológicas emocionales (Ítems 41–43) [CONDICIONAL]','Tabla 3 (Guía II) — Bloque “Atención a clientes y usuarios”','Responder solo si aplica.',2219,1,'2026-02-25 08:38:55','2026-02-25 08:38:55'),
(48,'GII · Liderazgo y relaciones / Relaciones / Deficiente relación con colaboradores que supervisa (Ítems 44–46) [CONDICIONAL]','Tabla 3 (Guía II) — Bloque “Jefatura”','Responder solo si aplica.',2220,1,'2026-02-25 08:38:55','2026-02-25 08:38:55'),
(49,'GIII · Ambiente / Condiciones en el ambiente / Condiciones peligrosas e inseguras (Ítems 1,3)','Tabla 6 (Guía III) — Dominio: Condiciones en el ambiente de trabajo','Considere los últimos 2 meses.',3301,1,'2026-02-25 08:38:55','2026-02-25 08:38:55'),
(50,'GIII · Ambiente / Condiciones en el ambiente / Condiciones deficientes e insalubres (Ítems 2,4)','Tabla 6 (Guía III) — Dominio: Condiciones en el ambiente de trabajo','Considere los últimos 2 meses.',3302,1,'2026-02-25 08:38:55','2026-02-25 08:38:55'),
(51,'GIII · Ambiente / Condiciones en el ambiente / Trabajos peligrosos (Ítem 5)','Tabla 6 (Guía III) — Dominio: Condiciones en el ambiente de trabajo','Considere los últimos 2 meses.',3303,1,'2026-02-25 08:38:55','2026-02-25 08:38:55'),
(52,'GIII · Factores propios / Carga de trabajo / Cargas cuantitativas (Ítems 6,12)','Tabla 6 (Guía III) — Dominio: Carga de trabajo','Considere los últimos 2 meses.',3304,1,'2026-02-25 08:38:55','2026-02-25 08:38:55'),
(53,'GIII · Factores propios / Carga de trabajo / Ritmos acelerados (Ítems 7,8)','Tabla 6 (Guía III) — Dominio: Carga de trabajo','Considere los últimos 2 meses.',3305,1,'2026-02-25 08:38:55','2026-02-25 08:38:55'),
(54,'GIII · Factores propios / Carga de trabajo / Carga mental (Ítems 9,10,11)','Tabla 6 (Guía III) — Dominio: Carga de trabajo','Considere los últimos 2 meses.',3306,1,'2026-02-25 08:38:55','2026-02-25 08:38:55'),
(55,'GIII · Factores propios / Carga de trabajo / Cargas de alta responsabilidad (Ítems 13,14)','Tabla 6 (Guía III) — Dominio: Carga de trabajo','Considere los últimos 2 meses.',3307,1,'2026-02-25 08:38:55','2026-02-25 08:38:55'),
(56,'GIII · Factores propios / Carga de trabajo / Cargas contradictorias o inconsistentes (Ítems 15,16)','Tabla 6 (Guía III) — Dominio: Carga de trabajo','Considere los últimos 2 meses.',3308,1,'2026-02-25 08:38:55','2026-02-25 08:38:55'),
(57,'GIII · Falta de control / Control y autonomía (Ítems 25–28)','Tabla 6 (Guía III) — Dominio: Falta de control sobre el trabajo','Considere los últimos 2 meses.',3309,1,'2026-02-25 08:38:55','2026-02-25 08:38:55'),
(58,'GIII · Falta de control / Desarrollo (Ítems 23,24)','Tabla 6 (Guía III) — Dominio: Falta de control sobre el trabajo','Considere los últimos 2 meses.',3310,1,'2026-02-25 08:38:55','2026-02-25 08:38:55'),
(59,'GIII · Falta de control / Manejo del cambio (Ítems 29,30)','Tabla 6 (Guía III) — Dominio: Falta de control sobre el trabajo','Considere los últimos 2 meses.',3311,1,'2026-02-25 08:38:55','2026-02-25 08:38:55'),
(60,'GIII · Falta de control / Capacitación (Ítems 35,36)','Tabla 6 (Guía III) — Dominio: Falta de control sobre el trabajo','Considere los últimos 2 meses.',3312,1,'2026-02-25 08:38:55','2026-02-25 08:38:55'),
(61,'GIII · Organización del tiempo / Jornada / Jornadas extensas (Ítems 17,18)','Tabla 6 (Guía III) — Dominio: Jornada de trabajo','Considere los últimos 2 meses.',3313,1,'2026-02-25 08:38:55','2026-02-25 08:38:55'),
(62,'GIII · Organización del tiempo / Trabajo-familia / Influencia fuera del centro (Ítems 19,20)','Tabla 6 (Guía III) — Dominio: Interferencia trabajo-familia','Considere los últimos 2 meses.',3314,1,'2026-02-25 08:38:55','2026-02-25 08:38:55'),
(63,'GIII · Organización del tiempo / Trabajo-familia / Influencia responsabilidades familiares (Ítems 21,22)','Tabla 6 (Guía III) — Dominio: Interferencia trabajo-familia','Considere los últimos 2 meses.',3315,1,'2026-02-25 08:38:55','2026-02-25 08:38:55'),
(64,'GIII · Liderazgo / Escasa claridad de funciones (Ítems 31–34)','Tabla 6 (Guía III) — Dominio: Liderazgo','Considere los últimos 2 meses.',3316,1,'2026-02-25 08:38:55','2026-02-25 08:38:55'),
(65,'GIII · Liderazgo / Características del liderazgo (Ítems 37–41)','Tabla 6 (Guía III) — Dominio: Liderazgo','Considere los últimos 2 meses.',3317,1,'2026-02-25 08:38:55','2026-02-25 08:38:55'),
(66,'GIII · Relaciones / Relaciones sociales en el trabajo (Ítems 42–46)','Tabla 6 (Guía III) — Dominio: Relaciones en el trabajo','Considere los últimos 2 meses.',3318,1,'2026-02-25 08:38:55','2026-02-25 08:38:55'),
(67,'GIII · Violencia / Violencia laboral (Ítems 57–64)','Tabla 6 (Guía III) — Dominio: Violencia','Considere los últimos 2 meses.',3319,1,'2026-02-25 08:38:55','2026-02-25 08:38:55'),
(68,'GIII · Entorno organizacional / Reconocimiento / Retroalimentación del desempeño (Ítems 47,48)','Tabla 6 (Guía III) — Dominio: Reconocimiento del desempeño','Considere los últimos 2 meses.',3320,1,'2026-02-25 08:38:55','2026-02-25 08:38:55'),
(69,'GIII · Entorno organizacional / Reconocimiento / Reconocimiento y compensación (Ítems 49–52)','Tabla 6 (Guía III) — Dominio: Reconocimiento del desempeño','Considere los últimos 2 meses.',3321,1,'2026-02-25 08:38:55','2026-02-25 08:38:55'),
(70,'GIII · Entorno organizacional / Pertenencia / Inestabilidad laboral (Ítems 53,54)','Tabla 6 (Guía III) — Dominio: Sentido de pertenencia e inestabilidad','Considere los últimos 2 meses.',3322,1,'2026-02-25 08:38:55','2026-02-25 08:38:55'),
(71,'GIII · Entorno organizacional / Pertenencia / Sentido de pertenencia (Ítems 55,56)','Tabla 6 (Guía III) — Dominio: Sentido de pertenencia e inestabilidad','Considere los últimos 2 meses.',3323,1,'2026-02-25 08:38:55','2026-02-25 08:38:55'),
(72,'GIII · Factores propios / Carga de trabajo / Cargas psicológicas emocionales (Ítems 65–68) [CONDICIONAL]','Tabla 6 (Guía III) — Bloque “Atención a clientes y usuarios”','Responder solo si aplica.',3324,1,'2026-02-25 08:38:55','2026-02-25 08:38:55'),
(73,'GIII · Relaciones / Supervisión / Deficiente relación con colaboradores que supervisa (Ítems 69–72) [CONDICIONAL]','Tabla 6 (Guía III) — Bloque “Jefatura”','Responder solo si aplica.',3325,1,'2026-02-25 08:38:55','2026-02-25 08:38:55'),
(74,'GIV · Prevencion de Riesgos Psicosociales ','Politica de Prevencion de Riesgos Psicosociales','Completa tus datos. Esta información no afecta tu calificación.',4100,1,'2026-02-25 09:05:10','2026-02-26 07:45:58'),
(75,'GV · Datos del trabajador','Guía de Referencia V (clasificación/agrupación)','Completa tus datos. Esta información no afecta tu calificación.',5100,1,'2026-02-25 09:05:10','2026-02-26 07:43:50'),
(76,'GIV Prevención de Riesgos Psicosociales (GIV)','El contenido de esta guía es un complemento para la mejor comprensión de la presente Norma, y no es de cumplimiento obligatorio.','Este apartado es informativo.',4090,1,'2026-02-26 07:55:00','2026-02-26 07:55:29');

/*Table structure for table `nom035_submission_category_scores` */

DROP TABLE IF EXISTS `nom035_submission_category_scores`;

CREATE TABLE `nom035_submission_category_scores` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `submission_id` bigint unsigned NOT NULL,
  `category` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `score` decimal(10,2) NOT NULL DEFAULT '0.00',
  `risk_level` varchar(50) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_nom035_cat_submission_category` (`submission_id`,`category`),
  KEY `idx_nom035_cat_submission` (`submission_id`),
  KEY `idx_nom035_cat_category` (`category`),
  CONSTRAINT `fk_nom035_cat_submission` FOREIGN KEY (`submission_id`) REFERENCES `nom035_submissions` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=32 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

/*Data for the table `nom035_submission_category_scores` */

insert  into `nom035_submission_category_scores`(`id`,`submission_id`,`category`,`score`,`risk_level`,`created_at`,`updated_at`) values 
(1,51,'Alta responsabilidad',14.00,NULL,'2026-03-13 14:15:39','2026-03-13 14:15:39'),
(2,51,'Ambiente de trabajo',15.00,NULL,'2026-03-13 14:15:39','2026-03-13 14:15:39'),
(3,51,'Atención a clientes',24.00,NULL,'2026-03-13 14:15:39','2026-03-13 14:15:39'),
(4,51,'Autonomía',12.00,NULL,'2026-03-13 14:15:39','2026-03-13 14:15:39'),
(5,51,'Cambio',6.00,NULL,'2026-03-13 14:15:39','2026-03-13 14:15:39'),
(6,51,'Capacitación',12.00,NULL,'2026-03-13 14:15:39','2026-03-13 14:15:39'),
(7,51,'Carga de trabajo',17.00,NULL,'2026-03-13 14:15:39','2026-03-13 14:15:39'),
(8,51,'Carga mental',17.00,NULL,'2026-03-13 14:15:39','2026-03-13 14:15:39'),
(9,51,'Claridad/Información',19.00,NULL,'2026-03-13 14:15:39','2026-03-13 14:15:39'),
(10,51,'Condiciones de trabajo',8.00,NULL,'2026-03-13 14:15:39','2026-03-13 14:15:39'),
(11,51,'Control/Autonomía',8.00,NULL,'2026-03-13 14:15:39','2026-03-13 14:15:39'),
(12,51,'Control/Desarrollo',8.00,NULL,'2026-03-13 14:15:39','2026-03-13 14:15:39'),
(13,51,'Desarrollo',6.00,NULL,'2026-03-13 14:15:39','2026-03-13 14:15:39'),
(14,51,'Jefatura',23.00,NULL,'2026-03-13 14:15:39','2026-03-13 14:15:39'),
(15,51,'Jornada',12.00,NULL,'2026-03-13 14:15:39','2026-03-13 14:15:39'),
(16,51,'Liderazgo',15.00,NULL,'2026-03-13 14:15:39','2026-03-13 14:15:39'),
(17,51,'Órdenes contradictorias',11.00,NULL,'2026-03-13 14:15:39','2026-03-13 14:15:39'),
(18,51,'Reconocimiento/Estabilidad',32.00,NULL,'2026-03-13 14:15:39','2026-03-13 14:15:39'),
(19,51,'Relación con compañeros',5.00,NULL,'2026-03-13 14:15:39','2026-03-13 14:15:39'),
(20,51,'Relación con jefe',4.00,NULL,'2026-03-13 14:15:39','2026-03-13 14:15:39'),
(21,51,'Relaciones',13.00,NULL,'2026-03-13 14:15:39','2026-03-13 14:15:39'),
(22,51,'Trabajo-familia',18.00,NULL,'2026-03-13 14:15:39','2026-03-13 14:15:39'),
(23,51,'Violencia laboral',51.00,NULL,'2026-03-13 14:15:39','2026-03-13 14:15:39');

/*Table structure for table `nom035_submission_domain_scores` */

DROP TABLE IF EXISTS `nom035_submission_domain_scores`;

CREATE TABLE `nom035_submission_domain_scores` (
  `submission_id` bigint unsigned NOT NULL,
  `domain` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `score` int NOT NULL,
  `risk_level` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  PRIMARY KEY (`submission_id`,`domain`),
  CONSTRAINT `nom035_submission_domain_scores_ibfk_1` FOREIGN KEY (`submission_id`) REFERENCES `nom035_submissions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

/*Data for the table `nom035_submission_domain_scores` */

insert  into `nom035_submission_domain_scores`(`submission_id`,`domain`,`score`,`risk_level`) values 
(51,'Carga de trabajo',40,'Bajo'),
(51,'Condiciones de trabajo',8,'Nulo'),
(51,'Condiciones en el ambiente de trabajo',11,'Nulo'),
(51,'Falta de control sobre el trabajo',52,'Medio'),
(51,'Insuficiente sentido de pertenencia e inestabilidad',9,'Nulo'),
(51,'Interferencia trabajo-familia',10,'Nulo'),
(51,'Jornada de trabajo',4,'Nulo'),
(51,'Liderazgo y relaciones en el trabajo',46,'Medio'),
(51,'Prueba',1,'Nulo'),
(51,'Reconocimiento del desempeño',18,'Nulo'),
(51,'Violencia',24,'Bajo'),
(52,'Acontecimiento traumático severo',0,'Nulo'),
(52,'Afectación',0,'Nulo'),
(52,'Evitación',0,'Nulo'),
(52,'Recuerdos persistentes',0,'Nulo');

/*Table structure for table `nom035_submission_profile` */

DROP TABLE IF EXISTS `nom035_submission_profile`;

CREATE TABLE `nom035_submission_profile` (
  `submission_id` bigint unsigned NOT NULL,
  `user_id` int NOT NULL,
  `questionnaire_no` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `applied_date` date DEFAULT NULL,
  `sex` enum('M','F') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `age_range` enum('15 – 19','20 – 24','25 – 29','30 – 34','35 – 39','40 – 44','45 – 49','50 – 54','55 – 59','60 – 64','65 – 69','70 o más') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `marital_status` enum('Casado','Divorciado','Soltero','Viudo','Unión libre') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `education_level` enum('Primaria terminada','Primaria incompleta','Secundaria terminada','Secundaria incompleta','Preparatoria/Bachillerato terminado','Preparatoria/Bachillerato incompleto','Técnico Superior terminado','Técnico Superior incompleto','Licenciatura terminada','Licenciatura incompleta','Maestría terminada','Maestría incompleta','Doctorado terminado','Doctorado incompleto','Sin formación') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `area_id` int DEFAULT NULL,
  `position_id` int DEFAULT NULL,
  `job_type` enum('operativo','supervisor','profesional_tecnico','gerente') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `hiring_type` enum('obra_proyecto','indeterminado','temporal','honorarios') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `staff_type` enum('sindicalizado','confianza','ninguno') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `workday_type` enum('fijo_nocturno','fijo_mixto','fijo_diurno') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `shift_rotation` enum('si','no') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `time_current_position` enum('Menos de 6 meses','Entre 6 meses y 1 año','Entre 1 a 4 años','Entre 5 a 9 años','Entre 10 a 14 años','Entre 15 a 19 años','Entre 20 a 24 años','25 años o más') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `total_work_experience` enum('Menos de 6 meses','Entre 6 meses y 1 año','Entre 1 a 4 años','Entre 5 a 9 años','Entre 10 a 14 años','Entre 15 a 19 años','Entre 20 a 24 años','25 años o más') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`submission_id`),
  KEY `idx_nsp_user` (`user_id`),
  KEY `idx_nsp_area` (`area_id`),
  KEY `idx_nsp_position` (`position_id`),
  CONSTRAINT `fk_nsp_area` FOREIGN KEY (`area_id`) REFERENCES `areas` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_nsp_position` FOREIGN KEY (`position_id`) REFERENCES `positions` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_nsp_submission` FOREIGN KEY (`submission_id`) REFERENCES `nom035_submissions` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_nsp_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/*Data for the table `nom035_submission_profile` */

insert  into `nom035_submission_profile`(`submission_id`,`user_id`,`questionnaire_no`,`applied_date`,`sex`,`age_range`,`marital_status`,`education_level`,`area_id`,`position_id`,`job_type`,`hiring_type`,`staff_type`,`workday_type`,`shift_rotation`,`time_current_position`,`total_work_experience`,`created_at`) values 
(51,1,'1','0000-00-00','F','30 – 34','Divorciado','Secundaria terminada',1,1,'gerente','temporal','confianza','fijo_diurno','no','Entre 10 a 14 años','Entre 10 a 14 años','2026-03-13 12:46:59'),
(52,4,'1','2026-03-13',NULL,NULL,NULL,NULL,24,121,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-03-13 14:03:25'),
(54,9,'1','2026-03-17',NULL,NULL,NULL,NULL,24,123,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-03-17 08:23:00'),
(55,11,'1','2026-03-17',NULL,NULL,NULL,NULL,24,120,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-03-17 10:16:26'),
(56,12,'1','2026-03-17',NULL,NULL,NULL,NULL,18,62,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-03-17 10:18:47'),
(57,13,'1','2026-03-17',NULL,NULL,NULL,NULL,11,36,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-03-17 10:20:14'),
(58,15,'1','2026-03-17',NULL,NULL,NULL,NULL,9,32,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-03-17 11:44:42'),
(59,16,'1','2026-03-17',NULL,NULL,NULL,NULL,35,169,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-03-17 11:46:01'),
(60,17,'1','2026-03-17',NULL,NULL,NULL,NULL,18,64,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-03-17 11:48:31'),
(61,35,'1','2026-03-19',NULL,NULL,NULL,NULL,19,69,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-03-19 10:00:41');

/*Table structure for table `nom035_submissions` */

DROP TABLE IF EXISTS `nom035_submissions`;

CREATE TABLE `nom035_submissions` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `cycle_id` bigint unsigned NOT NULL,
  `user_id` int NOT NULL,
  `status` enum('available','in_progress','submitted') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'available',
  `started_at` datetime DEFAULT NULL,
  `submitted_at` datetime DEFAULT NULL,
  `score_total` int DEFAULT NULL,
  `risk_level` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `observations` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
  `locked` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_nom035_submissions_cycle_user` (`cycle_id`,`user_id`),
  KEY `idx_nom035_submissions_user_status` (`user_id`,`status`),
  KEY `idx_nom035_submissions_cycle_status` (`cycle_id`,`status`),
  KEY `idx_nom035_submissions_cycle` (`cycle_id`),
  KEY `idx_nom035_submissions_user` (`user_id`),
  CONSTRAINT `fk_nom035_submissions_cycle` FOREIGN KEY (`cycle_id`) REFERENCES `nom035_cycles` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_nom035_submissions_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=62 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

/*Data for the table `nom035_submissions` */

insert  into `nom035_submissions`(`id`,`cycle_id`,`user_id`,`status`,`started_at`,`submitted_at`,`score_total`,`risk_level`,`observations`,`locked`,`created_at`,`updated_at`) values 
(51,1,1,'submitted','2026-03-13 19:46:58','2026-03-13 19:52:47',233,'Muy Alto',NULL,1,'2026-03-13 12:46:52','2026-03-13 12:52:48'),
(52,1,4,'submitted','2026-03-13 21:03:24','2026-03-13 21:04:01',0,'Bajo',NULL,1,'2026-03-13 14:03:19','2026-03-13 14:04:02'),
(53,1,5,'available',NULL,NULL,NULL,NULL,NULL,0,'2026-03-13 14:13:46','2026-03-13 14:13:46'),
(54,1,9,'submitted','2026-03-17 15:23:00','2026-03-17 15:23:36',0,'Nulo',NULL,1,'2026-03-17 08:22:54','2026-03-17 08:23:37'),
(55,1,11,'submitted','2026-03-17 17:16:25','2026-03-17 17:17:21',NULL,NULL,NULL,1,'2026-03-17 10:16:19','2026-03-17 10:17:21'),
(56,1,12,'submitted','2026-03-17 17:18:47','2026-03-17 17:19:18',NULL,NULL,NULL,1,'2026-03-17 10:18:38','2026-03-17 10:19:18'),
(57,1,13,'submitted','2026-03-17 17:20:13','2026-03-17 17:21:58',NULL,NULL,NULL,1,'2026-03-17 10:20:08','2026-03-17 10:21:59'),
(58,1,15,'submitted','2026-03-17 18:44:41','2026-03-17 18:45:17',NULL,NULL,NULL,1,'2026-03-17 11:44:36','2026-03-17 11:45:18'),
(59,1,16,'submitted','2026-03-17 18:46:00','2026-03-17 18:46:30',NULL,NULL,NULL,1,'2026-03-17 11:45:55','2026-03-17 11:46:30'),
(60,1,17,'submitted','2026-03-17 18:48:30','2026-03-17 18:49:04',NULL,NULL,NULL,1,'2026-03-17 11:48:20','2026-03-17 11:49:05'),
(61,1,35,'submitted','2026-03-19 17:00:40','2026-03-19 17:01:35',NULL,NULL,NULL,1,'2026-03-19 10:00:35','2026-03-19 10:01:36');

/*Table structure for table `nom035_user_profile` */

DROP TABLE IF EXISTS `nom035_user_profile`;

CREATE TABLE `nom035_user_profile` (
  `user_id` int NOT NULL,
  `questionnaire_no` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `applied_date` date DEFAULT NULL,
  `sex` enum('M','F') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `age_range` enum('15 – 19','20 – 24','25 – 29','30 – 34','35 – 39','40 – 44','45 – 49','50 – 54','55 – 59','60 – 64','65 – 69','70 o más') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `marital_status` enum('Casado','Divorciado','Soltero','Viudo','Unión libre') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `education_level` enum('Primaria terminada','Primaria incompleta','Secundaria terminada','Secundaria incompleta','Preparatoria/Bachillerato terminado','Preparatoria/Bachillerato incompleto','Técnico Superior terminado','Técnico Superior incompleto','Licenciatura terminada','Licenciatura incompleta','Maestría terminada','Maestría incompleta','Doctorado terminado','Doctorado incompleto','Sin formación') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `area_id` int DEFAULT NULL,
  `position_id` int DEFAULT NULL,
  `job_type` enum('operativo','supervisor','profesional_tecnico','gerente') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `hiring_type` enum('obra_proyecto','indeterminado','temporal','honorarios') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `staff_type` enum('sindicalizado','confianza','ninguno') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `workday_type` enum('fijo_nocturno','fijo_mixto','fijo_diurno') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `shift_rotation` enum('si','no') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `time_current_position` enum('Menos de 6 meses','Entre 6 meses y 1 año','Entre 1 a 4 años','Entre 5 a 9 años','Entre 10 a 14 años','Entre 15 a 19 años','Entre 20 a 24 años','25 años o más') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `total_work_experience` enum('Menos de 6 meses','Entre 6 meses y 1 año','Entre 1 a 4 años','Entre 5 a 9 años','Entre 10 a 14 años','Entre 15 a 19 años','Entre 20 a 24 años','25 años o más') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`),
  KEY `fk_nom035_profile_area` (`area_id`),
  KEY `fk_nom035_profile_position` (`position_id`),
  CONSTRAINT `fk_nom035_profile_area` FOREIGN KEY (`area_id`) REFERENCES `areas` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_nom035_profile_position` FOREIGN KEY (`position_id`) REFERENCES `positions` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_nom035_profile_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/*Data for the table `nom035_user_profile` */

insert  into `nom035_user_profile`(`user_id`,`questionnaire_no`,`applied_date`,`sex`,`age_range`,`marital_status`,`education_level`,`area_id`,`position_id`,`job_type`,`hiring_type`,`staff_type`,`workday_type`,`shift_rotation`,`time_current_position`,`total_work_experience`,`updated_at`) values 
(1,'1','0000-00-00','F','30 – 34','Divorciado','Secundaria terminada',1,1,'gerente','temporal','confianza','fijo_diurno','no','Entre 10 a 14 años','Entre 10 a 14 años','2026-03-13 12:52:46'),
(4,'1','2026-03-13',NULL,NULL,NULL,NULL,24,121,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-03-13 14:03:57'),
(5,'1','2026-03-13',NULL,NULL,NULL,NULL,29,146,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-03-13 11:51:44'),
(6,'1','2026-03-13',NULL,NULL,NULL,NULL,29,143,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-03-13 12:07:18'),
(9,'1','2026-03-17',NULL,NULL,NULL,NULL,24,123,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-03-17 08:23:30'),
(11,'1','2026-03-17',NULL,NULL,NULL,NULL,24,120,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-03-17 10:17:17'),
(12,'1','2026-03-17',NULL,NULL,NULL,NULL,18,62,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-03-17 10:19:14'),
(13,'1','2026-03-17',NULL,NULL,NULL,NULL,11,36,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-03-17 10:21:53'),
(15,'1','2026-03-17',NULL,NULL,NULL,NULL,9,32,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-03-17 11:45:14'),
(16,'1','2026-03-17',NULL,NULL,NULL,NULL,35,169,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-03-17 11:46:26'),
(17,'1','2026-03-17',NULL,NULL,NULL,NULL,18,64,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-03-17 11:48:59'),
(35,'1','2026-03-19',NULL,NULL,NULL,NULL,19,69,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-03-19 10:01:11');

/*Table structure for table `notices` */

DROP TABLE IF EXISTS `notices`;

CREATE TABLE `notices` (
  `id` int NOT NULL AUTO_INCREMENT,
  `title` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `body` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `image_url` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `image_urls` json DEFAULT NULL,
  `plant` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `active` tinyint(1) NOT NULL DEFAULT '1',
  `created_by` int DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_notices_created_at` (`created_at`),
  KEY `idx_notices_plant_active` (`plant`,`active`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

/*Data for the table `notices` */

insert  into `notices`(`id`,`title`,`body`,`image_url`,`image_urls`,`plant`,`active`,`created_by`,`created_at`) values 
(1,'1','1',NULL,NULL,NULL,1,1,'2026-02-17 07:30:01'),
(2,'2','gjgjfjdd',NULL,NULL,NULL,1,1,'2026-02-17 07:31:02'),
(3,'ddd','ddd',NULL,NULL,NULL,1,1,'2026-02-17 07:37:18'),
(4,'encuesta','favor de responder lo antes posible su cuestionario ya que se va a cerrar la vista, gracias',NULL,NULL,NULL,1,NULL,'2026-02-17 15:09:45'),
(5,'hola','como estas',NULL,NULL,NULL,1,NULL,'2026-02-20 06:09:22');

/*Table structure for table `notifications` */

DROP TABLE IF EXISTS `notifications`;

CREATE TABLE `notifications` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int DEFAULT NULL,
  `title` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `message` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
  `readed` tinyint(1) DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

/*Data for the table `notifications` */

/*Table structure for table `password_reset_tokens` */

DROP TABLE IF EXISTS `password_reset_tokens`;

CREATE TABLE `password_reset_tokens` (
  `email` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `token` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/*Data for the table `password_reset_tokens` */

/*Table structure for table `password_resets` */

DROP TABLE IF EXISTS `password_resets`;

CREATE TABLE `password_resets` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `code` varchar(6) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `expires_at` datetime NOT NULL,
  `used` tinyint(1) DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `password_resets_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

/*Data for the table `password_resets` */

insert  into `password_resets`(`id`,`user_id`,`code`,`expires_at`,`used`,`created_at`) values 
(1,1,'977375','2026-02-11 15:50:05',0,'2026-02-11 07:40:05'),
(2,1,'027164','2026-02-11 15:59:59',0,'2026-02-11 07:49:58'),
(3,1,'751367','2026-02-11 16:01:40',0,'2026-02-11 07:51:39'),
(4,1,'767677','2026-02-11 16:02:24',0,'2026-02-11 07:52:24'),
(5,1,'308545','2026-02-11 16:03:00',0,'2026-02-11 07:53:00'),
(6,1,'907550','2026-02-11 17:21:31',0,'2026-02-11 09:11:31'),
(7,1,'155365','2026-02-11 17:23:57',0,'2026-02-11 09:13:56'),
(8,1,'049019','2026-02-11 17:35:14',0,'2026-02-11 09:25:13'),
(9,1,'971058','2026-02-11 17:51:05',0,'2026-02-11 09:41:04'),
(10,1,'190780','2026-02-11 17:53:36',0,'2026-02-11 09:43:36'),
(11,1,'539453','2026-02-11 18:57:01',1,'2026-02-11 10:47:01'),
(12,1,'506907','2026-02-11 18:57:56',1,'2026-02-11 10:47:55'),
(13,1,'343526','2026-02-11 18:58:45',1,'2026-02-11 10:48:44'),
(14,1,'939238','2026-03-09 15:14:44',1,'2026-03-09 08:04:43');

/*Table structure for table `positions` */

DROP TABLE IF EXISTS `positions`;

CREATE TABLE `positions` (
  `id` int NOT NULL AUTO_INCREMENT,
  `area_id` int DEFAULT NULL,
  `name` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `active` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_positions_name_area` (`name`,`area_id`),
  KEY `fk_positions_area` (`area_id`),
  CONSTRAINT `fk_positions_area` FOREIGN KEY (`area_id`) REFERENCES `areas` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=202 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

/*Data for the table `positions` */

insert  into `positions`(`id`,`area_id`,`name`,`active`) values 
(1,1,'AGENTE DE VENTAS\r\n',1),
(2,1,'CHOFER\r\n',1),
(3,1,'AUXILIAR ADMINISTRATIVO\r\n',1),
(4,2,'AYUDANTE GENERAL\r\n',1),
(5,2,'JEFE DE ALMACEN DE M. P\r\n',1),
(6,2,'OPERADOR DE MONTACARGAS\r\n',1),
(7,3,'ALMACENISTA\r\n',1),
(8,3,'AUXILIAR DE ALMACEN',1),
(9,3,'AYUDANTE DE ALMACEN\r\n',1),
(10,3,'AYUDANTE GENERAL',1),
(11,3,'CHOFER\r\n',1),
(12,3,'JEFE DE ALMACEN DE P . T\r\n',1),
(13,3,'OPERADOR DE MONTACARGAS\r\n',1),
(14,4,'ENCARGADO ALM REFACC Y SUMINIS',1),
(15,4,'AYUDANTE GENERAL\r\n',1),
(16,5,'APLICADOR\r\n',1),
(17,5,'AUXILIAR DE CALIDAD\r\n',1),
(19,5,'INSPECTOR CALIDAD MOLINOS\r\n',1),
(20,6,'AGENTE DE VENTAS\r\n',1),
(21,6,'CHOFER\r\n',1),
(22,7,'AGENTE DE VENTAS\r\n',1),
(23,8,'AGENTE DE VENTAS\r\n',1),
(24,8,'ASISTENTE DE GERENCIA ADMTIVA\r\n',1),
(25,8,'AUXILIAR ADMINISTRATIVO\r\n',1),
(26,8,'CHOFER\r\n',1),
(27,8,'COBRADOR\r\n',1),
(28,8,'GERENTE REGIONAL CENTRO\r\n',1),
(29,8,'INTENDENCIA\r\n',1),
(30,8,'SORIANO DIAZ JOSE ANGEL\r\n',1),
(31,8,'SERVICIO TECNICO\r\n',1),
(32,9,'ENCARGADA DE COMPRAS\r\n',1),
(33,9,'AUXILIAR DE COMPRAS\r\n',1),
(34,10,'CONTRALOR\r\n',1),
(35,10,'AUXILIAR DE CONTRALORIA\r\n',1),
(36,11,'COORDINADOR ISO\r\n',1),
(37,11,'AUXILIAR DE COORDINACION ISO\r\n',1),
(38,12,'ENCARGADA DECREDITO Y COBRANZA\r\n',1),
(39,12,'AUXILIAR DE CREDITO Y COBRANZA\r\n',1),
(40,13,'ASISTENTE GERENCIA OPERACIONES\r\n',1),
(41,13,'ANALISTA\r\n',1),
(42,13,'DIRECTOR DE OPERACIONES\r\n',1),
(43,14,'ASISTENTE DE DIRECCION GENERAL\r\n',1),
(44,14,'ASISTENTE DE GERENCIA ADMTIVA\r\n',1),
(45,15,'DIRECTORA JURIDICA\r\n',1),
(46,16,'AYUDANTE GENERAL\r\n',1),
(47,16,'CAPTURISTA DE EXTRUSION\r\n',1),
(48,16,'JEFE DE EXTRUSION\r\n',1),
(49,16,'JEFE DE PRODUCCION\r\n',1),
(50,16,'OPERADOR DE EXTRUSOR\r\n',1),
(51,16,'OPERADOR DE MONTACARGAS\r\n',1),
(52,16,'SUPERVISOR DE EXTRUSION\r\n',1),
(53,17,'AYUDANTE DE FORMULADOR\r\n',1),
(54,17,'AYUDANTE GENERAL\r\n',1),
(55,17,'CAPTURISTA DE FORMULACION\r\n',1),
(56,17,'OPERADOR DE FORMULACION\r\n',1),
(57,17,'OPERADOR DE MONTACARGAS\r\n',1),
(58,17,'OPERADOR DE PESAJE AUTOMATICO',1),
(59,17,'OPERADOR MEZCLADORA ALTA VELOC\r\n',1),
(60,17,'SUPERVISOR DE FORMULACION\r\n',1),
(61,18,'ASISTENTE DE GERENCIA ADMTIVA\r\n',1),
(62,18,'AUXILIAR ADMINISTRATIVO\r\n',1),
(63,18,'AYUDANTE GENERAL\r\n',1),
(64,18,'CHOFER\r\n',1),
(65,18,'INTENDENCIA\r\n',1),
(66,18,'MENSAJERO\r\n',1),
(67,19,'ADMINISTRADORA DE SAP\r\n',1),
(68,19,'AUXILIAR ADMINISTRATIVO\r\n',1),
(69,19,'AUXILIAR CONTABLE\r\n',1),
(70,19,'AUXILIAR CONTABLE FISCAL\r\n',1),
(71,19,'AUXILIAR DE COMERCIO EXTERIOR\r\n',1),
(72,19,'AYUDANTE DE MECANICO\r\n',1),
(73,19,'CONTADOR GENERAL\r\n',1),
(74,19,'ENCARGADO DE ACTIVO FIJO\r\n',1),
(75,19,'FACTURACION\r\n',1),
(76,20,'APLICADOR\r\n',1),
(77,20,'ASISTENTE CALIDAD SISTEMA ISO\r\n',1),
(78,20,'AUXILIAR DE CALIDAD\r\n',1),
(79,20,'AUXILIAR DE TESTIGOS\r\n',1),
(80,20,'AUXILIAR SUPERVISOR CALIDAD\r\n',1),
(81,20,'AYUDANTE DE CALIDAD\r\n',1),
(82,20,'AYUDANTE DE EVALUADOR DE M.P.\r\n',1),
(83,20,'AYUDANTE GENERAL\r\n',1),
(84,20,'CAPTURA Y RECOPILACION  DATOS\r\n',1),
(85,20,'ENCARGADO DE PREMUESTRAS\r\n',1),
(86,20,'EVALUA DESARROLLOS Y SMALL BAT\r\n',1),
(87,20,'EVALUADOR DE MATERIA PRIMA\r\n',1),
(88,20,'GERENTE DE CONTROL DE CALIDAD\r\n',1),
(89,20,'INSPECTOR  CALIDAD  MEZCLAS\r\n',1),
(90,20,'INSPECTOR CALIDAD MOLINOS\r\n',1),
(91,20,'INSPECTOR COND PROCESO EXTRUSI\r\n',1),
(92,20,'JEFE DE PRUEBAS DE INTERPERISM\r\n',1),
(93,20,'NOTIFICADOR',1),
(94,20,'OPERADOR DE EQUIPO MALVERN\r\n',1),
(95,20,'OPERADOR DE MICROMOLINO\r\n',1),
(96,20,'OPERADOR DE MONTACARGAS\r\n',1),
(97,20,'PREMUESTRAS\r\n',1),
(98,20,'SUPERVISOR DE INSPECCION\r\n',1),
(99,20,'SUPERVISOR DE INSPECTORES\r\n',1),
(100,21,'APLICADOR\r\n',1),
(101,21,'AUXILIAR ADMINISTRATIVO\r\n',1),
(102,21,'AUXILIAR DE DESARROLLO\r\n',1),
(103,21,'AYUDANTE GENERAL\r\n',1),
(104,21,'GERENTE DE DESARROLLO\r\n',1),
(105,21,'JEFE DE TURNO DE DESARROLLO\r\n',1),
(106,21,'OPERADOR DE EXTRUSOR',1),
(107,21,'OPERADOR DE MICROEXTRUSOR\r\n',1),
(108,21,'OPERADOR DE MICROMOLINO\r\n',1),
(109,21,'OPERADOR DE MICROPULVERIZADOR\r\n',1),
(110,21,'PESADOR\r\n',1),
(111,22,'ASISTENTE GERENCIA OPERACIONES\r\n',1),
(112,22,'GERENTE DE OPERACIONES\r\n',1),
(113,23,'AUXILIAR ADMINISTRATIVO\r\n',1),
(114,23,'COORD DE TALENTO Y FORMACION\r\n',1),
(115,23,'GERENTE DE INGENIERIA Y MANTTO\r\n',1),
(116,23,'GERENTE DE PROYECTOS\r\n',1),
(117,24,'ADMR CALENDARIO PRODUCCION\r\n',1),
(118,24,'ANALISTA DE PRODUCCION EN SAP\r\n',1),
(119,24,'AUXILIAR DE PRODUCCION\r\n',1),
(120,24,'COORDINADOR DE PRODUCCION\r\n',1),
(121,24,'GERENTE DE PRODUCCION\r\n',1),
(122,24,'INTENDENCIA\r\n',1),
(123,24,'JEFE DE PRODUCCION\r\n',1),
(124,24,'PROGRAMADOR\r\n',1),
(125,25,'AUXILIAR DE RECURSOS HUMANOS\r\n',1),
(126,25,'AUXILIAR DE SEG E HIGIENE\r\n',1),
(127,25,'ENFERMERO GENERAL\r\n',1),
(128,25,'GERENTE DE RECURSOS HUMANOS\r\n',1),
(129,26,'AUXILIAR DE SISTEMAS\r\n',1),
(130,27,'AGENTE DE VENTAS\r\n',1),
(131,27,'AUXILIAR ADMINISTRATIVO\r\n',1),
(132,27,'CHOFER\r\n',1),
(133,27,'SERVICIO TECNICO\r\n',1),
(134,28,'AYUDANTE DE ELECTROMECANICO\r\n',1),
(135,28,'AYUDANTE GENERAL\r\n',1),
(136,28,'INTENDENCIA\r\n',1),
(137,28,'JEFE DE MANTENIMIENTO\r\n',1),
(138,28,'MECANICO AUTOMOTRIZ\r\n',1),
(139,28,'SUPERVISOR DE PISO\r\n',1),
(140,28,'SUPERVISOR DE TURNO\r\n',1),
(141,28,'TECNICO ELECTROMECANICO\r\n',1),
(142,29,'AUXILIAR DE INVENTARIOS\r\n',1),
(143,29,'AUXILIAR DE LOGISTICA\r\n',1),
(144,29,'AYUDANTE DE CHOFER\r\n',1),
(145,29,'CHOFER\r\n',1),
(146,29,'COORDINADORA DE LOGISTICA\r\n',1),
(147,30,'AUXILIAR DE MEJORA CONTINUA\r\n',1),
(148,30,'ENCARGADO DE MEJORA CONTINUA\r\n',1),
(149,30,'TOMADOR DE TIEMPOS\r\n',1),
(150,31,'AGENTE DE VENTAS\r\n',1),
(151,32,'AGENTE DE VENTAS\r\n',1),
(152,33,'AYUDANTE GENERAL\r\n',1),
(153,33,'CAPTURISTA DE MEZCLAS\r\n',1),
(154,33,'NOTIFICADOR\r\n',1),
(155,33,'OPERADOR  MEZCLADORA ROMBOIDAL\r\n',1),
(156,33,'OPERADOR DE BONDING\r\n',1),
(157,33,'OPERADOR DE EXTRUSOR\r\n',1),
(158,33,'OPERADOR DE MONTACARGAS\r\n',1),
(159,33,'SUPERVISOR DE MEZCLAS\r\n',1),
(160,34,'AYUDANTE GENERAL\r\n',1),
(161,34,'AYUDANTE OPERADOR MEZCLADORA\r\n',1),
(162,34,'SUPERVISOR MEZCLAS ALTA VELOC\r\n',1),
(163,35,'AYUDANTE  OPERADOR  MOLINOS\r\n',1),
(164,35,'AYUDANTE GENERAL\r\n',1),
(165,35,'CAPTURISTA DE MOLINOS\r\n',1),
(166,35,'LAVADOR\r\n',1),
(167,35,'OPERADOR DE MOLINOS\r\n',1),
(168,35,'OPERADOR DE MONTACARGAS\r\n',1),
(169,35,'SUPERVISOR DE MOLINOS\r\n',1),
(170,36,'AYUDANTE GENERAL\r\n',1),
(171,36,'ENCARGADO DE LIMPIEZA  MANGAS\r\n',1),
(172,36,'INTENDENCIA\r\n',1),
(173,36,'LAVADOR\r\n',1),
(174,36,'OPERADOR DE MOLINOS\r\n',1),
(175,36,'OPERADOR DE MONTACARGAS\r\n',1),
(176,36,'SUPERVISOR DE MOLINOS\r\n',1),
(177,37,'AGENTE DE VENTAS\r\n',1),
(178,37,'AUXILIAR ADMINISTRATIVO\r\n',1),
(179,37,'AUXILIAR DE ALMACEN\r\n',1),
(180,37,'CHOFER\r\n',1),
(181,37,'COORDINADORA DE SUCURSAL\r\n',1),
(182,37,'SERVICIO TECNICO\r\n',1),
(183,38,'APLICADOR\r\n',1),
(184,38,'AYUDANTE GENERAL\r\n',1),
(185,38,'ENCARGADO DE POLVOS FINOS\r\n',1),
(186,38,'OPERADOR DE MONTACARGAS\r\n',1),
(187,38,'SUPERVISOR DE POLVOS FINOS\r\n',1),
(188,39,'AGENTE DE VENTAS\r\n',1),
(189,39,'CHOFER\r\n',1),
(190,39,'COORDINADORA DE SUCURSAL',1),
(191,40,'AGENTE DE VENTAS\r\n',1),
(192,40,'CHOFER\r\n',1),
(193,40,'AUXILIAR ADMINISTRATIVO\r\n',1),
(194,41,'AGENTE DE VENTAS\r\n',1),
(195,42,'AUDITOR DE SEGURIDAD E HIGIENE\r\n',1),
(196,43,'AGENTE DE VENTAS\r\n',1),
(197,43,'CHOFER\r\n',1),
(198,44,'COORDINADORA DE SUCURSAL\r\n',1),
(199,44,'AGENTE DE VENTAS\r\n',1),
(200,44,'CHOFER\r\n',1),
(201,20,'JEFE DE TURNO DE CTROL CALIDAD',1);

/*Table structure for table `question_options` */

DROP TABLE IF EXISTS `question_options`;

CREATE TABLE `question_options` (
  `id` int NOT NULL AUTO_INCREMENT,
  `question_id` int NOT NULL,
  `option_text` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `is_correct` tinyint(1) NOT NULL DEFAULT '0',
  `sort_order` int NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  KEY `idx_options_question` (`question_id`,`sort_order`),
  CONSTRAINT `fk_options_question` FOREIGN KEY (`question_id`) REFERENCES `questions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

/*Data for the table `question_options` */

insert  into `question_options`(`id`,`question_id`,`option_text`,`is_correct`,`sort_order`) values 
(1,1,'Casco + lentes + botas',1,1),
(2,1,'Solo guantes',0,2),
(3,1,'Sin EPP si es rápido',0,3),
(4,3,'Señalizar el área',1,1),
(5,3,'Usar material absorbente',1,2),
(6,3,'Reportar al supervisor',1,3),
(7,3,'Ignorarlo y continuar',0,4);

/*Table structure for table `questions` */

DROP TABLE IF EXISTS `questions`;

CREATE TABLE `questions` (
  `id` int NOT NULL AUTO_INCREMENT,
  `section_id` int NOT NULL,
  `question_text` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `question_type` enum('single','multi','text') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `required` tinyint(1) NOT NULL DEFAULT '0',
  `points` decimal(10,2) NOT NULL DEFAULT '0.00',
  `sort_order` int NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  KEY `idx_questions_section` (`section_id`,`sort_order`),
  CONSTRAINT `fk_questions_section` FOREIGN KEY (`section_id`) REFERENCES `form_sections` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

/*Data for the table `questions` */

insert  into `questions`(`id`,`section_id`,`question_text`,`question_type`,`required`,`points`,`sort_order`) values 
(1,1,'¿Cuál es el EPP mínimo obligatorio en área de producción?','single',1,10.00,1),
(2,1,'Describe brevemente por qué es importante usar casco de seguridad.','text',1,10.00,2),
(3,2,'Selecciona las acciones correctas ante un derrame:','multi',1,10.00,1),
(4,2,'¿Qué harías si detectas una condición insegura?','text',1,10.00,2);

/*Table structure for table `roles` */

DROP TABLE IF EXISTS `roles`;

CREATE TABLE `roles` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

/*Data for the table `roles` */

insert  into `roles`(`id`,`name`) values 
(1,'Administrador'),
(3,'Empleado'),
(2,'Recursos Humanos');

/*Table structure for table `sessions` */

DROP TABLE IF EXISTS `sessions`;

CREATE TABLE `sessions` (
  `id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_id` bigint unsigned DEFAULT NULL,
  `ip_address` varchar(45) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `user_agent` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `payload` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `last_activity` int NOT NULL,
  PRIMARY KEY (`id`),
  KEY `sessions_user_id_index` (`user_id`),
  KEY `sessions_last_activity_index` (`last_activity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/*Data for the table `sessions` */

/*Table structure for table `submissions` */

DROP TABLE IF EXISTS `submissions`;

CREATE TABLE `submissions` (
  `id` int NOT NULL AUTO_INCREMENT,
  `form_id` int NOT NULL,
  `user_id` int NOT NULL,
  `status` enum('in_progress','submitted','reviewed') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'in_progress',
  `started_at` datetime DEFAULT NULL,
  `submitted_at` datetime DEFAULT NULL,
  `reviewed_at` datetime DEFAULT NULL,
  `score` decimal(10,2) DEFAULT NULL,
  `observations` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
  `reviewer_id` int DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_form_user` (`form_id`,`user_id`),
  KEY `idx_sub_status` (`status`),
  KEY `idx_sub_user` (`user_id`),
  KEY `fk_sub_reviewer` (`reviewer_id`),
  CONSTRAINT `fk_sub_form` FOREIGN KEY (`form_id`) REFERENCES `forms` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_sub_reviewer` FOREIGN KEY (`reviewer_id`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_sub_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

/*Data for the table `submissions` */

insert  into `submissions`(`id`,`form_id`,`user_id`,`status`,`started_at`,`submitted_at`,`reviewed_at`,`score`,`observations`,`reviewer_id`,`created_at`,`updated_at`) values 
(1,1,1,'in_progress','2026-02-19 15:07:44',NULL,NULL,NULL,NULL,NULL,'2026-02-19 15:07:44','2026-02-19 15:07:44');

/*Table structure for table `users` */

DROP TABLE IF EXISTS `users`;

CREATE TABLE `users` (
  `id` int NOT NULL AUTO_INCREMENT,
  `employee_number` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `name` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `email` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `curp` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `password` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `role_id` int DEFAULT NULL,
  `area` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `position` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `birthday` date DEFAULT NULL,
  `phone` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `entry_date` date DEFAULT NULL,
  `active` tinyint(1) DEFAULT '1',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `avatar` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `allowed_ips` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `plant` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `last_login` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `employee_number` (`employee_number`),
  KEY `fk_role` (`role_id`),
  CONSTRAINT `fk_role` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=84 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

/*Data for the table `users` */

insert  into `users`(`id`,`employee_number`,`name`,`email`,`curp`,`password`,`role_id`,`area`,`position`,`birthday`,`phone`,`entry_date`,`active`,`created_at`,`avatar`,`allowed_ips`,`plant`,`last_login`) values 
(1,'485','OLMEDO MORALES ANA KAREN','al221411711@gmail.com','OEMA950117MMCLRN07','$2b$12$smxdkVjpbk6M.1wv.leqs.uMDnG8YDYvIjriBzVO2VfM7M.1FP4d2',1,'21','101','2019-03-13','7291429242','2019-03-13',1,'2026-02-11 09:00:29','/static/avatars/1_451d2d0e286149098b676f2c52104936.png',NULL,'Vitracoat','2026-03-24 07:47:31'),
(4,'1','ARTEAGA MOJICA RAMON','rarteaga@vitracoat.com',NULL,'$2b$12$CEY38ACx.d1vxmkIT3iPhOvgE/LkjLor7ZT4Fbbt0IvxHecXU7OPy',3,'24','121','1995-02-19',NULL,'1993-07-01',1,'2026-02-16 12:31:36',NULL,NULL,'Vitracoat','2026-03-13 14:03:13'),
(5,'2','DE LA HUERTA SANCHEZ GENOVEVA','sales@vitracoat.com',NULL,'$2b$12$uiLfJQct7YX39lVG8YYh5Oxrg0r6YJtMWv5JAF3XkVjlgKB1FXGRe',3,'29','146','1995-02-05',NULL,'1993-07-01',1,'2026-02-17 12:29:36',NULL,NULL,'Vitracoat','2026-03-13 14:04:54'),
(6,'3','FLORES FLORES MARIA DEL PILAR',NULL,NULL,'$2b$12$ZCxcD8V6a4qTVfPm5Ghnau1NolYWuKgvHmUDbM9.pXwYqOVF16YeS',3,'29','143','1995-03-11',NULL,'1991-05-23',1,'2026-02-17 12:33:55',NULL,NULL,'Vitracoat','2026-03-13 12:06:26'),
(7,'5','FERNANDEZ SANCHEZ MARIA AGUSTINA',NULL,NULL,'$2b$12$mwEUlAk6lY9DuzRtoGMFu.Xhys34bMc25K79YbUMyDw312KV01vOK',3,'18','62',NULL,NULL,'1993-02-18',1,'2026-02-17 12:34:56',NULL,NULL,'Vitracoat','2026-03-12 09:17:03'),
(8,'7','REYES SANCHEZ PATRICIA ESPERANZA',NULL,NULL,'$2b$12$cHIkDgk3RimQTS5EeWQd2O0xI.ufEoQZTb2ZaqjwypRX/qcycVhQS',3,'19','73',NULL,NULL,'1993-08-16',1,'2026-02-17 12:35:57',NULL,NULL,'Vitracoat','2026-03-12 12:31:02'),
(9,'8','PEREZ ESPINOSA CARLOS',NULL,NULL,'$2b$12$5x03rZFE4NShve1IzcFqqeyUnUDLX8MejdW18WL6Y7LYT4uhS6bPa',3,'24','123',NULL,NULL,'1993-08-16',1,'2026-02-17 12:37:59',NULL,NULL,'Vitracoat','2026-03-17 08:22:45'),
(10,'9','VELASCO VELASCO CATALINA',NULL,NULL,'$2b$12$TP2.dBwcytajPMoqx3d.HePb3CfCK8RlYMfAtc4fF/K9CeUZkAyWu',3,'12','38',NULL,NULL,'1993-02-01',1,'2026-02-17 12:39:04',NULL,NULL,'Vitracoat','2026-02-18 12:54:49'),
(11,'10','HUERTA MACIAS LUIS IGNACIO',NULL,NULL,'$2b$12$fmRnFFzHO03S4UckM3rMT.ILuBQr5cFE1NVfhqYFJLfydkfb5GyQ6',3,'24','120',NULL,NULL,'1994-01-04',1,'2026-02-17 12:40:37',NULL,NULL,'Vitracoat','2026-03-17 10:16:07'),
(12,'11','GARCIA MARTINEZ LAURA',NULL,NULL,'$2b$12$0lb9b4VB1PDRIxQwKWZyfOqVGh3jQ0bqqzdB19lLt2uIj/jaFS8gW',3,'18','62',NULL,NULL,'1998-05-28',1,'2026-02-17 12:42:22',NULL,NULL,'Vitracoat','2026-03-17 10:18:29'),
(13,'13','ATILANO ROMERO ANTONIO',NULL,NULL,'$2b$12$ZqJRqyD5jd/0qGW3dcvgiO2tExe7kp5bv4xNd0F0xbuHQ214UUsum',3,'11','36',NULL,NULL,'1996-04-10',1,'2026-02-17 12:43:29',NULL,NULL,'Vitracoat','2026-03-17 10:19:56'),
(14,'14','SANCHEZ SANCHEZ ADELINA VIOLETA',NULL,NULL,'$2b$12$KkM5a5QJzJKsq5df6aRsnOPIN3MwvqTe5MtL6z4vHCKqfEi6jlJqm',3,'25','128',NULL,NULL,'1996-05-13',1,'2026-02-17 12:44:57',NULL,NULL,'Vitracoat',NULL),
(15,'17','FLORES LOPEZ EVELIA',NULL,NULL,'$2b$12$CTaXH4oYi4V5MjXS7qP1aOEvWG0S.4pJJCKcRUZh5neCe61uFBXkG',3,'9','32',NULL,NULL,'1997-01-13',1,'2026-02-17 12:46:06',NULL,NULL,'Vitracoat','2026-03-17 11:44:28'),
(16,'18','VAZQUEZ GARCIA RICARDO',NULL,NULL,'$2b$12$DHubYm9UDDwAT5EIa4zQm.xSMOn8OwHnMA7UK1EmE3RUTajZrod5O',3,'35','169',NULL,NULL,'1994-02-15',1,'2026-02-17 12:47:44',NULL,NULL,'Vitracoat','2026-03-17 11:45:47'),
(17,'19','MENDOZA ZUÑIGA JOSE MANUEL FELIX',NULL,NULL,'$2b$12$MF10PoyrPLcM4z7Sgal/RukZoJSo9z6v0FdZ2mNimD5n9BDUqcbyS',3,'18','64',NULL,NULL,'1997-07-16',1,'2026-02-17 12:48:37',NULL,NULL,'Vitracoat','2026-03-17 11:48:14'),
(18,'21','GONZALEZ RAMIREZ ALEJANDRO',NULL,NULL,'$2b$12$TpFIwtfI08QTqlxBAsGSEOb7vEJC0fmghmKmYjIrjBJvWnJtCioim',3,'20','88',NULL,NULL,'1997-08-25',1,'2026-02-17 12:49:35',NULL,NULL,'Vitracoat',NULL),
(19,'22','LOPEZ VELAZQUEZ CARMELO',NULL,NULL,'$2b$12$XPswMfliDhtJ679FgNIB2e7A3ifHAHQwv.mDZQv9G7AEgUkbJQrWe',3,'21','105',NULL,NULL,'1997-09-29',1,'2026-02-17 12:53:47',NULL,NULL,'Vitracoat',NULL),
(20,'23','CLEMENTE ABAD MARIA DE LOURDES',NULL,NULL,'$2b$12$bYXokYS43IxqIfQ3VieUjOqrWfVuuXjDSiSFkmgYHb1cZC9TkN4eS',3,'18','62',NULL,NULL,'1999-11-23',1,'2026-02-17 12:54:51',NULL,NULL,'Vitracoat',NULL),
(21,'24','CASTAÑEDA GONZALEZ OSCAR',NULL,NULL,'$2b$12$LjAzttK15/GS7uvk81Sxru5s8IBOiCq1Oymrp49lbaqnn..ocd2yC',3,'21','105',NULL,NULL,'2000-02-15',1,'2026-02-17 12:57:11',NULL,NULL,'Vitracoat',NULL),
(22,'25','CASTREJON FABILA LUIS MANUEL',NULL,NULL,'$2b$12$Xv2QHyT67WwDaQxHRvgHeeZLcCiY0M4YwuKekE22aJuMKlOgfUDDa',3,'18','66',NULL,NULL,'2000-04-03',1,'2026-02-17 12:58:16',NULL,NULL,'Vitracoat',NULL),
(23,'28','SIERRA MARTINEZ MERCED IRMA',NULL,NULL,'$2b$12$xUjwiNUWn.w1ViBdCuEQV.9oHGUgJiTvBwA2tNkhSP356HK7YUn.G',3,'19','69',NULL,NULL,'2000-06-09',1,'2026-02-17 14:49:30',NULL,NULL,'Vitracoat',NULL),
(24,'29','ALMAZAN CAMPOS ALEJANDRO','aalmazan@vitracoat.com',NULL,'$2b$12$E1wDUAs1OwpWiiBq4jg1WOOy7y5Ow/hj19i2W3.EaocdwvcPshVsq',3,'10','34',NULL,NULL,'2000-07-31',1,'2026-02-17 14:51:24',NULL,NULL,'Vitracoat',NULL),
(25,'30','VILLAR JIMENEZ ADRIANA','auxdireccion@vitracoat.com',NULL,'$2b$12$5RHpSOrN1UxUz8akdjCoN.mFfma2iDhyLunqVc.J5gUseLekkkrA2',3,'13','40',NULL,NULL,'2000-10-11',1,'2026-02-17 14:52:19',NULL,NULL,'Vitracoat','2026-02-17 14:52:49'),
(26,'830','GONZALEZ VILLANA BERENICE','bgonzalez@vitracoat.com',NULL,'$2b$12$17n67p0agfzdNLyzcL9sJum1lUo8nCSsy1WezEyRTydvKBxDAHVp.',2,'23','114',NULL,NULL,'2023-07-10',1,'2026-02-18 07:52:23',NULL,NULL,'Vitracoat','2026-02-20 06:20:33'),
(27,'33','RODEA RODEA ANGELA','arodea@vitracoat.com',NULL,'$2b$12$D.8eWpEsVQpdpGApkKZDpO28J32RC4XrADXQ3DajLZss0i.8Qspmq',3,'19','75',NULL,NULL,'2001-01-11',1,'2026-02-19 09:27:11',NULL,NULL,'Vitracoat','2026-02-19 09:59:33'),
(28,'35','SERRANO AGONIZANTE DALIN',NULL,NULL,'$2b$12$bN.uwJEReCKo/vEhCcfj4eMGLwmrTLKe2PRa05Lf72ZGEZAhF/t8m',3,'19','69',NULL,NULL,'2001-01-17',1,'2026-02-25 10:33:25',NULL,NULL,'Vitracoat',NULL),
(29,'36','PEREZ SANCHEZ MANUEL',NULL,NULL,'$2b$12$y3PRM2DnZ8s2Y2mEBOmTx.VHLP83pq.8n/Q4MEIE.YBvhw5MMYYTe',3,'35','169',NULL,NULL,'1992-07-06',1,'2026-02-25 10:36:28',NULL,NULL,'Vitracoat',NULL),
(30,'37','MONSALVO MIRANDA DARIO',NULL,NULL,'$2b$12$d14wtf3mjm2/pXVinFGGJOWqWXQkZ760BI8.n6ceLTyBvLmLbIhNK',3,'35','169',NULL,NULL,'1997-10-09',1,'2026-03-06 07:49:22',NULL,NULL,'Vitracoat',NULL),
(31,'38','RODRIGUEZ VALLE SAUL',NULL,NULL,'$2b$12$cm9fk8XmhYnFJU2lNrKGE.X.94rE.j86yTpE2S.1GC1zPP/JldIXW',3,'38','187',NULL,NULL,'1997-10-09',1,'2026-03-06 07:51:11',NULL,NULL,NULL,NULL),
(32,'39','BLANQUET LOPEZ MIGUEL',NULL,NULL,'$2b$12$3aYPbuBSQnYRFy8pAo0P7ewFRzG44ulUGINCuQnvo2QlybQAN7Wwq',3,'21','105',NULL,NULL,'2004-06-25',1,'2026-03-06 07:53:19',NULL,NULL,'Vitracoat',NULL),
(33,'40','ARTEAGA MOJICA ELI',NULL,NULL,'$2b$12$josOonPLS.FGlPSzAa0BP.AfUypnImwob6fqMmXJ.e2YNohOUgQ8S',3,'16','49',NULL,NULL,'2002-09-04',1,'2026-03-06 07:55:03',NULL,NULL,'Vitracoat',NULL),
(34,'41','IBARRA BONILLA MIREYA',NULL,NULL,'$2b$12$sbi6o6s7NJq7.HYa/UyEB.b72wQY47qTDkX7deU6rn/GshS68Xnb.',3,'19','69',NULL,NULL,'2003-06-04',1,'2026-03-06 07:56:15',NULL,NULL,'Vitracoat',NULL),
(35,'42','PERALTA VELAZQUEZ LAURA',NULL,NULL,'$2b$12$6bWV8/Tv2qdRE/fjgMuHiOJRG5yk5pZt1E.lqkgadDxM6Hejv18fC',3,'19','69',NULL,NULL,'2003-06-09',1,'2026-03-06 07:57:32',NULL,NULL,'Vitracoat','2026-03-19 10:00:28'),
(36,'43','FLORES BARRON NATALY',NULL,NULL,'$2b$12$qEethZmdeO52M4PNF3rDDefrOTR8CrSqenHpPIvIHaI7Dcv7QzPPK',3,'19','69',NULL,NULL,'2003-06-30',1,'2026-03-19 13:20:50',NULL,NULL,'Vitracoat',NULL),
(37,'45','SERNAS MARTINEZ AGEO',NULL,NULL,'$2b$12$GDRGlYuupxk76eLSzfYIWeWjQtWzmeOeqDjw170bxHMDXbwAeybO6',3,'33','159',NULL,NULL,'2003-06-30',1,'2026-03-19 13:22:05',NULL,NULL,'Vitracoat',NULL),
(38,'46','GUTIERREZ MORA RODRIGO',NULL,NULL,'$2b$12$oEpPmcY3qBzZwZMlzp.ZIuRSJxYNsceQbF0oXXfqqV14TCudm4wRi',3,'24','120',NULL,NULL,'2003-11-24',1,'2026-03-19 13:23:14',NULL,NULL,'Vitracoat',NULL),
(39,'47','GONZALEZ SANCHEZ LAURA BEATRIZ',NULL,NULL,'$2b$12$xKVYqDMgdVQwLrcsD8W2nOWOCrldllTLw8Mw6fMq2auGxAB2X0WiW',3,'37','181',NULL,NULL,'2004-02-02',1,'2026-03-19 13:24:10',NULL,NULL,'Vitracoat',NULL),
(40,'49','MEJIA MORALES DALILA',NULL,NULL,'$2b$12$MHmYQUHZ6WdaFvHtykJlFONokNdSUibjjqYhu7WH1kK0iW/M1IBAq',3,'20','92',NULL,NULL,'2004-05-03',1,'2026-03-19 13:25:15',NULL,NULL,'Vitracoat',NULL),
(41,'55','BERTAUD ELIZALDE YOLANDA',NULL,NULL,'$2b$12$i0lIECrYYGaPrg5rQsOnj.hbdBTUC5jWQ46zA6FUM0TJC1DkqFtZy',3,'44','198',NULL,NULL,'2006-02-01',1,'2026-03-19 13:29:16',NULL,NULL,'Vitracoat',NULL),
(42,'50','ROMERO MOTA OSCAR JONATHAN',NULL,NULL,'$2b$12$9rmrbrqyWp4WRT9a0FSFX.lkRCuGUHUct9exltqb6ZCjvxAJ4Wxwa',3,'20','201',NULL,NULL,'2004-05-19',1,'2026-03-19 13:48:11',NULL,NULL,'Vitracoat',NULL),
(43,'60','GUTIERREZ FLORES OLIVA',NULL,NULL,'$2b$12$o2fzUlsLRjQs.HBdaSFxx.9q5SIw61ZkHJWBHsvYjUw6cMRCKwcnW',3,'20','201',NULL,NULL,'2006-11-03',1,'2026-03-19 13:51:48',NULL,NULL,'Vitracoat',NULL),
(44,'62','MARTINEZ OCHOA SONIA KARINA',NULL,NULL,'$2b$12$IshGb6ZjfDWfn7buYaOOa.o7P2HGJAdv5ANm3n/5cqKOeHSWB0FEi',3,'27','131',NULL,NULL,'2006-11-13',1,'2026-03-19 13:53:11',NULL,NULL,'Vitracoat',NULL),
(45,'63','VENTURA DOMINGUEZ IDALIA',NULL,NULL,'$2b$12$A5QQo9weq/6TouBEahvbtODnfNGzxU3tZ88dFOP1X86lB/Uujh0oa',3,'18','65',NULL,NULL,'2007-01-30',1,'2026-03-19 13:54:03',NULL,NULL,'Vitracoat',NULL),
(46,'64','CARRANCO SANCHEZ SERGIO',NULL,NULL,'$2b$12$Clf3qmofXX4z2Zk.9VCNuuZdZxUpbGrHWwyKJBUzN1LvZbGUXNNUu',3,'19','68',NULL,NULL,'2007-04-13',1,'2026-03-19 13:59:01',NULL,NULL,'Vitracoat',NULL),
(47,'65','ALVA NAVARRETE ERIKA',NULL,NULL,'$2b$12$j3ZbjdvHQGhLYGNl8kih0OZQ6E8bMYG6PTf66kI8ko7iiEn2aRpva',3,'20','201',NULL,NULL,'2007-06-04',1,'2026-03-19 13:59:57',NULL,NULL,'Vitracoat',NULL),
(48,'67','GUERRERO VAZQUEZ GUILLERMO',NULL,NULL,'$2b$12$0Sv4uWEzL49YrWnzzm97re3eh2x.iJjqPqXH8Bl2YHHN6rEdq7NBG',3,'20','85',NULL,NULL,'2001-05-23',1,'2026-03-19 14:00:56',NULL,NULL,'Vitracoat',NULL),
(49,'68','GONZALEZ NICANOR FERNANDO',NULL,NULL,'$2b$12$7ohXXrelENmYpKHWkCzyq.bTGkShaSmrY4H0EPoPTLavxip3x43dG',3,'35','169',NULL,NULL,'2000-06-14',1,'2026-03-19 14:01:50',NULL,NULL,'Vitracoat',NULL),
(50,'69','QUIROZ TRIGOS RICARDO',NULL,NULL,'$2b$12$hqJICzDafGpXJWsgHCAnqe/ddFi8fwLoYIcj9uTL3IutpTz179QWe',3,'10','35',NULL,NULL,'2008-07-22',1,'2026-03-19 14:02:48',NULL,NULL,'Vitracoat',NULL),
(51,'70','VELA JIMENEZ MARIA ESTHER',NULL,NULL,'$2b$12$47q4xzzLmt2dWzoW44Md6.M0ixs6xkt5tbMeVj3VK4rnEf4tdGLYC',3,'19','67',NULL,NULL,'2008-09-17',1,'2026-03-19 14:03:45',NULL,NULL,'Vitracoat',NULL),
(52,'71','ROJAS RAMIREZ CESAR',NULL,NULL,'$2b$12$oNJ.ARHh87lBCXbKXAtwOuRr7pFcw4ypDUDLO7CqxiZKvJ6bOgvfO',3,'13','41',NULL,NULL,'2008-11-24',1,'2026-03-19 14:04:20',NULL,NULL,'Vitracoat',NULL),
(53,'77','ESTRADA GUADARRAMA JOSE ANGEL',NULL,NULL,'$2b$12$raoPg4zgVGp48.6J9yChbeE3jXW.MG5bfwl0ktNS5WG.fzT8L3vh.',3,'3','12',NULL,NULL,'2009-10-14',1,'2026-03-19 14:05:05',NULL,NULL,'Vitracoat',NULL),
(54,'79','POPOCA GARCIA JOSE',NULL,NULL,'$2b$12$Qslg54paMfmIF1XKONl7b.LP.6CKSLxeGXyaflp6KHGWlHR21eQ02',3,'23','115',NULL,NULL,'2010-08-03',1,'2026-03-19 14:05:56',NULL,NULL,'Vitracoat',NULL),
(55,'80','ARRIAGA GALAN HERIBERTO',NULL,NULL,'$2b$12$.W8h6o0w3gUXzpU.UJ1.feEeyC3VEsbR26H9ZNkM2vPwKFgr3iCSW',3,'34','162',NULL,NULL,'2007-07-11',1,'2026-03-19 14:06:50',NULL,NULL,'Vitracoat',NULL),
(56,'81','CHAVEZ BARRERA JUAN',NULL,NULL,'$2b$12$tFRhly9JztMIhJP1C.PUbu2R4cpYb4Akoeq9ig0o5VsfWw2iAydei',3,'2','5',NULL,NULL,'2010-12-20',1,'2026-03-19 14:07:52',NULL,NULL,'Vitracoat',NULL),
(57,'83','GONZALEZ ZEPEDA ANA GABRIELA',NULL,NULL,'$2b$12$ljr2hkFxllINHOvddYgvJ.efXjf.7Y35n9EnJLil8xkfIufKJ9DlG',3,'25','125',NULL,NULL,'2011-01-24',1,'2026-03-19 14:08:58',NULL,NULL,'Vitracoat',NULL),
(58,'84','VILLAVICENCIO PERDOMO JOANA',NULL,NULL,'$2b$12$aReiMxzeric6WPUtVEzA/unj7SnyGxGn9Bfb49gNkrPorwif9i3Qq',3,'19','69',NULL,NULL,'2011-01-24',1,'2026-03-19 14:09:57',NULL,NULL,'Vitracoat',NULL),
(59,'85','LOPEZ RIVERA YADIRA',NULL,NULL,'$2b$12$MsfUDuDub.IjWeqLve/Gu.QMF4GO7DR.2QYKfl5oQYgfeSYfhVTUK',3,'14','43',NULL,NULL,'2011-02-01',1,'2026-03-19 15:51:25',NULL,NULL,'Vitracoat',NULL),
(60,'88','MENDOZA ARELLANO ELMA CRISTIAN',NULL,NULL,'$2b$12$91csJ6XCtW9K8LwgOodlkeoyNckC/Mn03t2/rjBQO3FTOOS/qiwSq',3,'19','69',NULL,NULL,'2011-02-14',1,'2026-03-19 15:52:14',NULL,NULL,'Vitracoat',NULL),
(61,'92','PERDOMO BONILLA MERCEDES MIRIAM',NULL,NULL,'$2b$12$cO06zyT/3k4.LpwoEQQsWuXw.DExueHHGDLF4LTNB53M.S7yZDOvS',3,'20','94',NULL,NULL,'2009-09-24',1,'2026-03-19 15:53:26',NULL,NULL,'Vitracoat',NULL),
(62,'93','RIVERA CIPRIANO NAYELI',NULL,NULL,'$2b$12$HWvMEU2T3h7MHvuPu.HlL.nlqbQnb7xBq5XheR7u3qlWYreNB96E6',3,'20','94',NULL,NULL,'2010-05-17',1,'2026-03-19 15:54:22',NULL,NULL,'Vitracoat',NULL),
(63,'94','VENTURA MOTA ROLLER',NULL,NULL,'$2b$12$vMMAcsmPvKyKPbxKZFcomeUGFkNmGKkWLnt9SfV2oEMZTMiB7oWhO',3,'28','139',NULL,NULL,'2011-05-23',1,'2026-03-19 15:55:08',NULL,NULL,'Vitracoat',NULL),
(64,'99','FLORES BARRON ESPERANZA',NULL,NULL,'$2b$12$XuYlWa2yBRphGvcZD2bFPe5h/dSjafNUJGehoFq7Z8p7670ZNjwJq',3,'19','69',NULL,NULL,'2012-01-05',1,'2026-03-19 15:56:04',NULL,NULL,'Vitracoat',NULL),
(65,'107','LOZADA ROSAS SALUSTIA ALICIA',NULL,NULL,'$2b$12$yF.UZ8jbm/VMuetwZkeK3OPBTq7ljn5UB2CBCBamoLQTc22.32o3C',3,'37','178',NULL,NULL,'2012-01-02',1,'2026-03-19 15:57:28',NULL,NULL,'Vitracoat',NULL),
(66,'112','MENDEZ PANIAGUA CARLOS',NULL,NULL,'$2b$12$9ne7sqTf0bkybOxGRDuuteKaqZdn.a.4TDm5U/dZ.du9ud2grLSzm',3,'33','159',NULL,NULL,'2005-01-20',1,'2026-03-19 15:58:25',NULL,NULL,'Vitracoat',NULL),
(67,'113','VALDIVIA OLIVARES JULIO CESAR',NULL,NULL,'$2b$12$GllZhDKZF/r98hQlg6nKZezJVj19ej0yhc77Th8iEQch9VV0M2oBK',3,'21','101',NULL,NULL,'2012-02-01',1,'2026-03-19 15:59:25',NULL,NULL,'Vitracoat',NULL),
(68,'114','PANTALEON MARTINEZ DOMINGA',NULL,NULL,'$2b$12$vwRt6FQ/6QO5IUGWlqvCFOh6iP9vP7ffhM67lua029xb0TbDpUtda',3,'18','65',NULL,NULL,'2012-04-30',1,'2026-03-19 16:00:54',NULL,NULL,'Vitracoat',NULL),
(69,'115','SANCHEZ CORONA CECILIA',NULL,NULL,'$2b$12$xbEV.6HkBWWBIxMySuV6FOjp216hCyERU8/NuJEve7sqRxlLc1by.',3,'39','190',NULL,NULL,'2013-03-05',1,'2026-03-19 16:01:52',NULL,NULL,'Vitracoat',NULL),
(70,'116','SALAZAR VELAZQUEZ ANA MARIA',NULL,NULL,'$2b$12$4gvY7IBOmxbFF4oyV1iZ8OEl.JX9bAZz05hWeoIzMuajnT9W3E16K',3,'19','69',NULL,NULL,'2012-05-07',1,'2026-03-19 16:02:57',NULL,NULL,'Vitracoat',NULL),
(71,'124','SIERRA MARTINEZ NANCY',NULL,NULL,'$2b$12$XwgKS0u5Xyeb16yxZxqDX.MGDg4vHXEL2rJF5GUq0NNzBnpeOpfMW',3,'19','69',NULL,NULL,'2012-11-12',1,'2026-03-19 16:03:47',NULL,NULL,'Vitracoat',NULL),
(72,'126','SOSA SAUCEDO JUAN EDUARDO',NULL,NULL,'$2b$12$lDKmdDsvtlCX4xkKdgKLvOvrvR3RBY.n4Z7rQeNAyA8iDrqvXOgmq',3,'1','1',NULL,NULL,'2012-11-20',1,'2026-03-19 16:04:34',NULL,NULL,'Vitracoat',NULL),
(73,'129','FONSECA JUAREZ DAVID EDUARDO',NULL,NULL,'$2b$12$12UmyHNAFciscp6hdTD.1OGenISAqC84GW2gxkPIB5UE2wWXYzRdO',3,'16','52',NULL,NULL,'2013-01-02',1,'2026-03-19 16:05:28',NULL,NULL,'Vitracoat',NULL),
(74,'133','VARGAS FERNANDEZ NADIA ERANDI',NULL,NULL,'$2b$12$G2NiaqAnN3x5jHtuNSjUG.dMQ5DuL1ZVtCZ2JAn8sN55oTiHA1QJW',3,'12','39',NULL,NULL,'2013-01-24',1,'2026-03-19 16:06:14',NULL,NULL,'Vitracoat',NULL),
(75,'137','GONZALEZ AVILA JORGE',NULL,NULL,'$2b$12$cDsUrLSB.SkbFVbVsFG3E.8foN0qow7IPgVXeLfp764GxTH.ZSnPe',3,'20','99',NULL,NULL,'2011-02-14',1,'2026-03-19 16:07:09',NULL,NULL,'Vitracoat',NULL),
(76,'143','LOBATO CORTEZ OMAR',NULL,NULL,'$2b$12$k5GRYndYiZidue/ajJGzPeh/AwJuQI1lsW8sUgVStTNfcX2DRGUtS',3,'20','201',NULL,NULL,'2013-08-22',1,'2026-03-19 16:08:00',NULL,NULL,'Vitracoat',NULL),
(77,'145','PEREZ ESCUTIA JUAN MANUEL',NULL,NULL,'$2b$12$MQlxQRCjHy7HLlG7dHpz/.sikiRWfSYmayuAG9Drc7LiuyeYRadLe',3,'24','118',NULL,NULL,'2013-10-01',1,'2026-03-19 16:08:44',NULL,NULL,'Vitracoat',NULL),
(78,'149','ROMERO SANDOVAL GILBERTO OMAR',NULL,NULL,'$2b$12$cO1QwhiKhq9WQNQxJ3izZOsiJfZQVxIc7Aoytqfafs3GWQYwX1RT.',3,'24','119',NULL,NULL,'2013-10-16',1,'2026-03-19 16:09:49',NULL,NULL,'Vitracoat',NULL),
(79,'150','JIMENEZ SARA OMAR',NULL,NULL,'$2b$12$dYoj1jyeThO6Cl5diXTQlu67ZMhyIa.oWmLqdAxJAzG/kRYeHLYH.',3,'30','148',NULL,NULL,'2013-11-15',1,'2026-03-19 16:10:37',NULL,NULL,'Vitracoat',NULL),
(80,'153','MARIN CRUZ CARLOS ENRIQUE',NULL,NULL,'$2b$12$FquE4nZZyEf0fkK2sCT0JO1qthLt2aEoeo33MoJRYuC5PMEfAmzce',3,'33','153',NULL,NULL,'2014-01-20',1,'2026-03-19 16:11:30',NULL,NULL,'Vitracoat',NULL),
(81,'154','SIERRA MARTINEZ OMAR',NULL,NULL,'$2b$12$0wPlsQkcKtYMBR6vxZ4DNuVQsKuRfoazaaIlr/JKGngv5SOdBemeO',3,'17','60',NULL,NULL,'2014-01-20',1,'2026-03-19 16:12:13',NULL,NULL,'Vitracoat',NULL),
(82,'163','LEON DOMINGUEZ ALFREDO',NULL,NULL,'$2b$12$i20ofNx.jcLhEmvY.fo4C.oc9MoMddYuYpEskWIg6HeDyf2oH9/76',3,'38','187',NULL,NULL,'2007-07-24',1,'2026-03-19 16:13:05',NULL,NULL,'Vitracoat',NULL),
(83,'170','GONZALEZ RAMON EDER',NULL,NULL,'$2b$12$H2tuEVmPl0GzbkzcQChPF.jsPVVUNfkGAKeHg2vmZ63QkhLLSsUAK',3,'20','99',NULL,NULL,'2014-06-23',1,'2026-03-19 16:14:00',NULL,NULL,'Vitracoat',NULL);

/* Procedure structure for procedure `sp_nom035_snapshot_profile` */

/*!50003 DROP PROCEDURE IF EXISTS  `sp_nom035_snapshot_profile` */;

DELIMITER $$

/*!50003 CREATE DEFINER=`karen723434236`@`%.%` PROCEDURE `sp_nom035_snapshot_profile`(
    IN p_submission_id BIGINT UNSIGNED
)
BEGIN
    DECLARE v_user_id INT DEFAULT NULL;

    SELECT user_id
      INTO v_user_id
    FROM nom035_submissions
    WHERE id = p_submission_id
    LIMIT 1;

    IF v_user_id IS NOT NULL THEN

        INSERT INTO nom035_submission_profile (
            submission_id,
            user_id,
            questionnaire_no,
            applied_date,
            sex,
            age_range,
            marital_status,
            education_level,
            area_id,
            position_id,
            job_type,
            hiring_type,
            staff_type,
            workday_type,
            shift_rotation,
            time_current_position,
            total_work_experience
        )
        SELECT
            p_submission_id,
            up.user_id,
            up.questionnaire_no,
            up.applied_date,
            up.sex,
            up.age_range,
            up.marital_status,
            up.education_level,
            up.area_id,
            up.position_id,
            up.job_type,
            up.hiring_type,
            up.staff_type,
            up.workday_type,
            up.shift_rotation,
            up.time_current_position,
            up.total_work_experience
        FROM nom035_user_profile up
        WHERE up.user_id = v_user_id
        ON DUPLICATE KEY UPDATE
            user_id = VALUES(user_id),
            questionnaire_no = VALUES(questionnaire_no),
            applied_date = VALUES(applied_date),
            sex = VALUES(sex),
            age_range = VALUES(age_range),
            marital_status = VALUES(marital_status),
            education_level = VALUES(education_level),
            area_id = VALUES(area_id),
            position_id = VALUES(position_id),
            job_type = VALUES(job_type),
            hiring_type = VALUES(hiring_type),
            staff_type = VALUES(staff_type),
            workday_type = VALUES(workday_type),
            shift_rotation = VALUES(shift_rotation),
            time_current_position = VALUES(time_current_position),
            total_work_experience = VALUES(total_work_experience);

    END IF;
END */$$
DELIMITER ;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
