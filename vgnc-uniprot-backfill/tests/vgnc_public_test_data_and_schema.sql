/*
 Navicat MySQL Dump SQL

 Source Server         : GCP - HGNC
 Source Server Type    : MySQL
 Source Server Version : 80408 (8.4.8-google)
 Source Host           : 35.246.28.232:3306
 Source Schema         : vgnc_public_2026_07_05

 Target Server Type    : MySQL
 Target Server Version : 80408 (8.4.8-google)
 File Encoding         : 65001

 Date: 09/07/2026 12:27:30
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for alt_name
-- ----------------------------
DROP TABLE IF EXISTS `alt_name`;
CREATE TABLE `alt_name` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `nomenclature_type_id` int NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `unique_name` (`name`,`nomenclature_type_id`) USING BTREE,
  KEY `alt_name_idx_nomenclature_type_id` (`nomenclature_type_id`) USING BTREE,
  CONSTRAINT `alt_name_fk_nomenclature_type_id` FOREIGN KEY (`nomenclature_type_id`) REFERENCES `nomenclature_type` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=3414 DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for alt_symbol
-- ----------------------------
DROP TABLE IF EXISTS `alt_symbol`;
CREATE TABLE `alt_symbol` (
  `id` int NOT NULL AUTO_INCREMENT,
  `symbol` varchar(45) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `nomenclature_type_id` int NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `unique_symbol` (`symbol`,`nomenclature_type_id`) USING BTREE,
  KEY `alt_symbol_idx_nomenclature_type_id` (`nomenclature_type_id`) USING BTREE,
  CONSTRAINT `alt_symbol_fk_nomenclature_type_id` FOREIGN KEY (`nomenclature_type_id`) REFERENCES `nomenclature_type` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=1249 DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for assembly
-- ----------------------------
DROP TABLE IF EXISTS `assembly`;
CREATE TABLE `assembly` (
  `id` int NOT NULL AUTO_INCREMENT,
  `taxon_id` int NOT NULL,
  `source` varchar(128) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `name` varchar(128) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `genbank_assembly_accession` varchar(128) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `refseq_assembly_accession` varchar(128) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `is_current` tinyint(1) NOT NULL,
  `is_vgnc_default` tinyint(1) NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `unique_assembly` (`source`,`refseq_assembly_accession`,`genbank_assembly_accession`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=110 DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for assembly_has_chr
-- ----------------------------
DROP TABLE IF EXISTS `assembly_has_chr`;
CREATE TABLE `assembly_has_chr` (
  `assembly_id` int NOT NULL,
  `chr_id` int NOT NULL,
  PRIMARY KEY (`assembly_id`,`chr_id`) USING BTREE,
  KEY `assembly_has_chr_idx_assembly_id` (`assembly_id`) USING BTREE,
  KEY `assembly_has_chr_idx_chr_id` (`chr_id`) USING BTREE,
  CONSTRAINT `assembly_has_chr_fk_assembly_id` FOREIGN KEY (`assembly_id`) REFERENCES `assembly` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `assembly_has_chr_fk_chr_id` FOREIGN KEY (`chr_id`) REFERENCES `chromosomes` (`chr_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for change_type
-- ----------------------------
DROP TABLE IF EXISTS `change_type`;
CREATE TABLE `change_type` (
  `id` int NOT NULL AUTO_INCREMENT,
  `field_changed` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for chromosomes
-- ----------------------------
DROP TABLE IF EXISTS `chromosomes`;
CREATE TABLE `chromosomes` (
  `chr_id` int NOT NULL AUTO_INCREMENT,
  `taxon_id` int NOT NULL,
  `display_name` varchar(128) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `coord_system` varchar(128) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `refseq_accession` varchar(128) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `genbank_accession` varchar(128) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL DEFAULT '',
  `ensembl_accession` varchar(128) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `type` varchar(128) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `assigned_to` int DEFAULT NULL,
  PRIMARY KEY (`chr_id`) USING BTREE,
  KEY `chromosomes_idx_assigned_to` (`assigned_to`) USING BTREE,
  KEY `chromosomes_idx_taxon_id` (`taxon_id`) USING BTREE,
  KEY `unique_sp_chr` (`display_name`,`taxon_id`,`genbank_accession`) USING BTREE,
  CONSTRAINT `chromosomes_fk_assigned_to` FOREIGN KEY (`assigned_to`) REFERENCES `editor` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `chromosomes_fk_taxon_id` FOREIGN KEY (`taxon_id`) REFERENCES `species` (`taxon_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=407494 DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for comment
-- ----------------------------
DROP TABLE IF EXISTS `comment`;
CREATE TABLE `comment` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `comment` text CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `author_id` int NOT NULL,
  `locked` int DEFAULT NULL,
  `created` date NOT NULL,
  `publisher_id` int DEFAULT NULL,
  `status` enum('Pending','Approved','Withdrawn') CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL DEFAULT 'Pending',
  `status_date` date NOT NULL,
  `replace_id` int DEFAULT NULL,
  `replacement_id` int DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `unique_id` (`id`) USING BTREE,
  KEY `comment_fk_author_id` (`author_id`) USING BTREE,
  KEY `comment_fk_publisher_id` (`publisher_id`) USING BTREE,
  CONSTRAINT `comment_fk_author_id` FOREIGN KEY (`author_id`) REFERENCES `editor` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `comment_fk_publisher_id` FOREIGN KEY (`publisher_id`) REFERENCES `editor` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for database_resource
-- ----------------------------
DROP TABLE IF EXISTS `database_resource`;
CREATE TABLE `database_resource` (
  `id` int NOT NULL AUTO_INCREMENT,
  `db_name` varchar(128) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `db_display_name` varchar(128) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `url` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `external_link_template` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `priority` int DEFAULT NULL,
  `class` varchar(32) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=32 DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for editor
-- ----------------------------
DROP TABLE IF EXISTS `editor`;
CREATE TABLE `editor` (
  `id` int NOT NULL AUTO_INCREMENT,
  `display_name` varchar(128) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `first_name` varchar(128) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `last_name` varchar(128) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `email` varchar(128) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `password` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `current` tinyint(1) NOT NULL,
  `connected` tinyint(1) NOT NULL,
  `jwt_refresh` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for editor_has_type
-- ----------------------------
DROP TABLE IF EXISTS `editor_has_type`;
CREATE TABLE `editor_has_type` (
  `editor_id` int NOT NULL,
  `editor_type_id` int NOT NULL,
  PRIMARY KEY (`editor_id`,`editor_type_id`) USING BTREE,
  KEY `editor_has_type_idx_editor_id` (`editor_id`) USING BTREE,
  KEY `editor_has_type_idx_editor_type_id` (`editor_type_id`) USING BTREE,
  CONSTRAINT `editor_has_type_fk_editor_id` FOREIGN KEY (`editor_id`) REFERENCES `editor` (`id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `editor_has_type_fk_editor_type_id` FOREIGN KEY (`editor_type_id`) REFERENCES `editor_type` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for editor_type
-- ----------------------------
DROP TABLE IF EXISTS `editor_type`;
CREATE TABLE `editor_type` (
  `id` int NOT NULL,
  `type` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for ensembl_gene
-- ----------------------------
DROP TABLE IF EXISTS `ensembl_gene`;
CREATE TABLE `ensembl_gene` (
  `eg_id` int NOT NULL AUTO_INCREMENT,
  `taxon_id` int NOT NULL,
  `ens_release` int NOT NULL,
  `stable_id` varchar(128) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `locus_type` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `display_xref` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `description` text CHARACTER SET latin1 COLLATE latin1_swedish_ci,
  PRIMARY KEY (`eg_id`,`stable_id`) USING BTREE,
  UNIQUE KEY `unique_end` (`taxon_id`,`ens_release`,`stable_id`) USING BTREE,
  KEY `eg_stid_idx` (`stable_id`) USING BTREE,
  KEY `release_species` (`taxon_id`,`ens_release`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=6523409 DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for external_resource
-- ----------------------------
DROP TABLE IF EXISTS `external_resource`;
CREATE TABLE `external_resource` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL DEFAULT '',
  `url` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `description` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `approved` tinyint DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `unique_resource` (`name`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for family_has_resource
-- ----------------------------
DROP TABLE IF EXISTS `family_has_resource`;
CREATE TABLE `family_has_resource` (
  `family_id` int NOT NULL,
  `ext_id` int NOT NULL,
  PRIMARY KEY (`family_id`,`ext_id`) USING BTREE,
  KEY `family_has_resource_idx_family_id` (`family_id`) USING BTREE,
  KEY `family_has_resource_idx_ext_id` (`ext_id`) USING BTREE,
  CONSTRAINT `family_has_resource_fk_ext_id` FOREIGN KEY (`ext_id`) REFERENCES `external_resource` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `family_has_resource_fk_family_id` FOREIGN KEY (`family_id`) REFERENCES `family_new` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for family_has_specialist
-- ----------------------------
DROP TABLE IF EXISTS `family_has_specialist`;
CREATE TABLE `family_has_specialist` (
  `family_id` int NOT NULL,
  `specialist_id` int NOT NULL,
  PRIMARY KEY (`family_id`,`specialist_id`) USING BTREE,
  KEY `family_has_specialist_idx_family_id` (`family_id`) USING BTREE,
  KEY `family_has_specialist_idx_specialist_id` (`specialist_id`) USING BTREE,
  CONSTRAINT `family_has_specialist_fk_family_id` FOREIGN KEY (`family_id`) REFERENCES `family_new` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `family_has_specialist_fk_specialist_id` FOREIGN KEY (`specialist_id`) REFERENCES `specialist` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for family_has_xrefs
-- ----------------------------
DROP TABLE IF EXISTS `family_has_xrefs`;
CREATE TABLE `family_has_xrefs` (
  `family_id` int NOT NULL,
  `xref_id` int NOT NULL,
  `created_by` int NOT NULL,
  `curated` int NOT NULL,
  `created` date DEFAULT NULL,
  `modified` date DEFAULT NULL,
  PRIMARY KEY (`family_id`,`xref_id`,`created_by`) USING BTREE,
  KEY `family_has_xrefs_idx_created_by` (`created_by`) USING BTREE,
  KEY `family_has_xrefs_idx_family_id` (`family_id`) USING BTREE,
  KEY `family_has_xrefs_idx_xref_id` (`xref_id`) USING BTREE,
  CONSTRAINT `family_has_xrefs_fk_created_by` FOREIGN KEY (`created_by`) REFERENCES `editor` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `family_has_xrefs_fk_family_id` FOREIGN KEY (`family_id`) REFERENCES `family_new` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `family_has_xrefs_fk_xref_id` FOREIGN KEY (`xref_id`) REFERENCES `xref` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for family_new
-- ----------------------------
DROP TABLE IF EXISTS `family_new`;
CREATE TABLE `family_new` (
  `id` int NOT NULL AUTO_INCREMENT,
  `abbreviation` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT '',
  `name` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `curator_comment` text CHARACTER SET latin1 COLLATE latin1_swedish_ci,
  `status` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT '',
  `external_note` text CHARACTER SET latin1 COLLATE latin1_swedish_ci,
  `type` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT '',
  `desc_comment` text CHARACTER SET latin1 COLLATE latin1_swedish_ci,
  `desc_label` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT '',
  `desc_source` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT '',
  `desc_go` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT '',
  `typical_gene` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `editor_id` int NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `family_new_idx_editor_id` (`editor_id`) USING BTREE,
  KEY `fn_name_idx` (`name`) USING BTREE,
  CONSTRAINT `family_new_fk_editor_id` FOREIGN KEY (`editor_id`) REFERENCES `editor` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=403 DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for flag_class
-- ----------------------------
DROP TABLE IF EXISTS `flag_class`;
CREATE TABLE `flag_class` (
  `id` int NOT NULL AUTO_INCREMENT,
  `class` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `unique_class` (`class`,`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for gene_alt_name
-- ----------------------------
DROP TABLE IF EXISTS `gene_alt_name`;
CREATE TABLE `gene_alt_name` (
  `id` int NOT NULL AUTO_INCREMENT,
  `genefam_id` int NOT NULL,
  `name_id` int NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `unique_alt_name` (`genefam_id`,`name_id`) USING BTREE,
  KEY `gene_alt_name_idx_name_id` (`name_id`) USING BTREE,
  KEY `gene_alt_name_idx_genefam_id` (`genefam_id`) USING BTREE,
  CONSTRAINT `gene_alt_name_fk_genefam_id` FOREIGN KEY (`genefam_id`) REFERENCES `genefam` (`genefam_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `gene_alt_name_fk_name_id` FOREIGN KEY (`name_id`) REFERENCES `alt_name` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=9729 DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for gene_alt_symbol
-- ----------------------------
DROP TABLE IF EXISTS `gene_alt_symbol`;
CREATE TABLE `gene_alt_symbol` (
  `id` int NOT NULL AUTO_INCREMENT,
  `genefam_id` int NOT NULL,
  `symbol_id` int NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `unique_alt_symbol` (`genefam_id`,`symbol_id`) USING BTREE,
  KEY `gene_alt_symbol_idx_symbol_id` (`symbol_id`) USING BTREE,
  KEY `gene_alt_symbol_idx_genefam_id` (`genefam_id`) USING BTREE,
  CONSTRAINT `gene_alt_symbol_fk_genefam_id` FOREIGN KEY (`genefam_id`) REFERENCES `genefam` (`genefam_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `gene_alt_symbol_fk_symbol_id` FOREIGN KEY (`symbol_id`) REFERENCES `alt_symbol` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=2769 DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for gene_flag
-- ----------------------------
DROP TABLE IF EXISTS `gene_flag`;
CREATE TABLE `gene_flag` (
  `id` int NOT NULL AUTO_INCREMENT,
  `type` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `flag_class_id` int NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `unique_flag` (`type`,`flag_class_id`) USING BTREE,
  KEY `gene_flag_idx_flag_class_id` (`flag_class_id`) USING BTREE,
  CONSTRAINT `gene_flag_fk_flag_class_id` FOREIGN KEY (`flag_class_id`) REFERENCES `flag_class` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=26 DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for gene_group
-- ----------------------------
DROP TABLE IF EXISTS `gene_group`;
CREATE TABLE `gene_group` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `created_by` int NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `unique_group` (`name`) USING BTREE,
  KEY `gene_group_idx_created_by` (`created_by`) USING BTREE,
  CONSTRAINT `gene_group_fk_created_by` FOREIGN KEY (`created_by`) REFERENCES `editor` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for gene_has_comment
-- ----------------------------
DROP TABLE IF EXISTS `gene_has_comment`;
CREATE TABLE `gene_has_comment` (
  `comment_id` int unsigned NOT NULL AUTO_INCREMENT,
  `genefam_id` int DEFAULT NULL,
  `editor` int DEFAULT NULL,
  PRIMARY KEY (`comment_id`) USING BTREE,
  UNIQUE KEY `unique_comment` (`genefam_id`,`comment_id`,`editor`) USING BTREE,
  CONSTRAINT `gene_has_comment_fk_comment_id` FOREIGN KEY (`comment_id`) REFERENCES `comment` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `gene_has_comment_fk_genefam_id` FOREIGN KEY (`genefam_id`) REFERENCES `genefam` (`genefam_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for gene_has_editor
-- ----------------------------
DROP TABLE IF EXISTS `gene_has_editor`;
CREATE TABLE `gene_has_editor` (
  `genefam_id` int NOT NULL,
  `editor_id` int NOT NULL,
  PRIMARY KEY (`genefam_id`,`editor_id`) USING BTREE,
  KEY `gene_has_editor_idx_editor_id` (`editor_id`) USING BTREE,
  KEY `gene_has_editor_idx_genefam_id` (`genefam_id`) USING BTREE,
  CONSTRAINT `gene_has_editor_fk_editor_id` FOREIGN KEY (`editor_id`) REFERENCES `editor` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `gene_has_editor_fk_genefam_id` FOREIGN KEY (`genefam_id`) REFERENCES `genefam` (`genefam_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for gene_has_family
-- ----------------------------
DROP TABLE IF EXISTS `gene_has_family`;
CREATE TABLE `gene_has_family` (
  `genefam_id` int NOT NULL,
  `family_id` int NOT NULL,
  `url` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `custom_sort` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  PRIMARY KEY (`genefam_id`,`family_id`) USING BTREE,
  KEY `gene_has_family_idx_family_id` (`family_id`) USING BTREE,
  KEY `gene_has_family_idx_genefam_id` (`genefam_id`) USING BTREE,
  CONSTRAINT `gene_has_family_fk_family_id` FOREIGN KEY (`family_id`) REFERENCES `family_new` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for gene_has_flag
-- ----------------------------
DROP TABLE IF EXISTS `gene_has_flag`;
CREATE TABLE `gene_has_flag` (
  `genefam_id` int NOT NULL,
  `flag_id` int NOT NULL,
  PRIMARY KEY (`genefam_id`,`flag_id`) USING BTREE,
  KEY `gene_has_flag_idx_flag_id` (`flag_id`) USING BTREE,
  CONSTRAINT `gene_has_flag_fk_flag_id` FOREIGN KEY (`flag_id`) REFERENCES `gene_flag` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for gene_has_group
-- ----------------------------
DROP TABLE IF EXISTS `gene_has_group`;
CREATE TABLE `gene_has_group` (
  `genefam_id` int NOT NULL,
  `group_id` int NOT NULL,
  PRIMARY KEY (`genefam_id`,`group_id`) USING BTREE,
  KEY `gene_has_group_idx_genefam_id` (`genefam_id`) USING BTREE,
  KEY `gene_has_group_idx_group_id` (`group_id`) USING BTREE,
  CONSTRAINT `gene_has_group_fk_genefam_id` FOREIGN KEY (`genefam_id`) REFERENCES `genefam` (`genefam_id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `gene_has_group_fk_group_id` FOREIGN KEY (`group_id`) REFERENCES `gene_group` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for gene_has_location
-- ----------------------------
DROP TABLE IF EXISTS `gene_has_location`;
CREATE TABLE `gene_has_location` (
  `gene_id` int NOT NULL,
  `source` varchar(128) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `location_id` int NOT NULL,
  `assembly_id` int NOT NULL,
  PRIMARY KEY (`gene_id`,`source`,`assembly_id`) USING BTREE,
  KEY `gene_has_location_idx_assembly_id` (`assembly_id`) USING BTREE,
  KEY `gene_has_location_idx_location_id` (`location_id`) USING BTREE,
  CONSTRAINT `gene_has_location_fk_assembly_id` FOREIGN KEY (`assembly_id`) REFERENCES `assembly` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `gene_has_location_fk_location_id` FOREIGN KEY (`location_id`) REFERENCES `gene_location` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for gene_has_locus_type
-- ----------------------------
DROP TABLE IF EXISTS `gene_has_locus_type`;
CREATE TABLE `gene_has_locus_type` (
  `genefam_id` int NOT NULL,
  `locus_type_id` int NOT NULL,
  PRIMARY KEY (`genefam_id`) USING BTREE,
  UNIQUE KEY `unique_gene_locus_type` (`genefam_id`,`locus_type_id`) USING BTREE,
  KEY `gene_has_locus_type_idx_locus_type_id` (`locus_type_id`) USING BTREE,
  KEY `genefam_id` (`genefam_id`) USING BTREE,
  CONSTRAINT `gene_has_locus_type_fk_genefam_id` FOREIGN KEY (`genefam_id`) REFERENCES `genefam` (`genefam_id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `gene_has_locus_type_fk_locus_type_id` FOREIGN KEY (`locus_type_id`) REFERENCES `locus_type` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for gene_has_note
-- ----------------------------
DROP TABLE IF EXISTS `gene_has_note`;
CREATE TABLE `gene_has_note` (
  `genefam_id` int NOT NULL,
  `note_id` int NOT NULL,
  `date_added` date NOT NULL,
  `editor` int NOT NULL,
  PRIMARY KEY (`genefam_id`,`note_id`) USING BTREE,
  KEY `gene_has_note_idx_comment_id` (`note_id`) USING BTREE,
  KEY `gene_has_note_idx_genefam_id` (`genefam_id`) USING BTREE,
  KEY `editor` (`editor`) USING BTREE,
  CONSTRAINT `gene_has_note_fk_comment_id` FOREIGN KEY (`note_id`) REFERENCES `gene_note` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `gene_has_note_fk_editor_id` FOREIGN KEY (`editor`) REFERENCES `editor` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `gene_has_note_fk_genefam_id` FOREIGN KEY (`genefam_id`) REFERENCES `genefam` (`genefam_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for gene_has_release_date
-- ----------------------------
DROP TABLE IF EXISTS `gene_has_release_date`;
CREATE TABLE `gene_has_release_date` (
  `genefam_id` int NOT NULL,
  `release_id` int NOT NULL,
  PRIMARY KEY (`genefam_id`,`release_id`) USING BTREE,
  KEY `gene_has_release_date_release_date_id_fk` (`release_id`) USING BTREE,
  CONSTRAINT `gene_has_release_date_genefam_id_fk` FOREIGN KEY (`genefam_id`) REFERENCES `genefam` (`genefam_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `gene_has_release_date_release_date_id_fk` FOREIGN KEY (`release_id`) REFERENCES `release_date` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------
-- Table structure for gene_has_sequence
-- ----------------------------
DROP TABLE IF EXISTS `gene_has_sequence`;
CREATE TABLE `gene_has_sequence` (
  `genefam_id` int NOT NULL,
  `sequence_id` int NOT NULL,
  PRIMARY KEY (`genefam_id`,`sequence_id`) USING BTREE,
  KEY `gene_has_sequence_idx_sequence_id` (`sequence_id`) USING BTREE,
  KEY `gene_has_sequence_idx_genefam_id` (`genefam_id`) USING BTREE,
  CONSTRAINT `gene_has_sequence_fk_genefam_id` FOREIGN KEY (`genefam_id`) REFERENCES `genefam` (`genefam_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `gene_has_sequence_fk_sequence_id` FOREIGN KEY (`sequence_id`) REFERENCES `sequence` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for gene_has_species
-- ----------------------------
DROP TABLE IF EXISTS `gene_has_species`;
CREATE TABLE `gene_has_species` (
  `genefam_id` int NOT NULL,
  `taxon_id` int NOT NULL,
  PRIMARY KEY (`genefam_id`,`taxon_id`) USING BTREE,
  KEY `gene_has_species_idx_genefam_id` (`genefam_id`) USING BTREE,
  KEY `gene_has_species_idx_taxon_id` (`taxon_id`) USING BTREE,
  KEY `genefam_id` (`genefam_id`) USING BTREE,
  CONSTRAINT `gene_has_species_fk_genefam_id` FOREIGN KEY (`genefam_id`) REFERENCES `genefam` (`genefam_id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `gene_has_species_fk_taxon_id` FOREIGN KEY (`taxon_id`) REFERENCES `species` (`taxon_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for gene_has_xrefs
-- ----------------------------
DROP TABLE IF EXISTS `gene_has_xrefs`;
CREATE TABLE `gene_has_xrefs` (
  `genefam_id` int NOT NULL,
  `xref_id` int NOT NULL,
  `created_by` int NOT NULL,
  `curated` int NOT NULL,
  `created` date DEFAULT NULL,
  `modified` date DEFAULT NULL,
  PRIMARY KEY (`genefam_id`,`xref_id`,`created_by`) USING BTREE,
  UNIQUE KEY `unique_genefam_xref` (`genefam_id`,`xref_id`) USING BTREE,
  KEY `gene_has_xrefs_idx_genefam_id` (`genefam_id`) USING BTREE,
  KEY `gene_has_xrefs_idx_created_by` (`created_by`) USING BTREE,
  KEY `gene_has_xrefs_idx_xref_id` (`xref_id`) USING BTREE,
  CONSTRAINT `gene_has_xrefs_fk_created_by` FOREIGN KEY (`created_by`) REFERENCES `editor` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `gene_has_xrefs_fk_genefam_id` FOREIGN KEY (`genefam_id`) REFERENCES `genefam` (`genefam_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `gene_has_xrefs_fk_xref_id` FOREIGN KEY (`xref_id`) REFERENCES `xref` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for gene_history
-- ----------------------------
DROP TABLE IF EXISTS `gene_history`;
CREATE TABLE `gene_history` (
  `id` int NOT NULL AUTO_INCREMENT,
  `log` text CHARACTER SET latin1 COLLATE latin1_swedish_ci,
  `date` date NOT NULL,
  `genefam_id` int NOT NULL,
  `editor_id` int NOT NULL,
  `type_id` int NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `gene_history_idx_type_id` (`type_id`) USING BTREE,
  KEY `gene_history_idx_genefam_id` (`genefam_id`) USING BTREE,
  KEY `gh_genefamid_idx` (`genefam_id`) USING BTREE,
  CONSTRAINT `gene_history_fk_genefam_id` FOREIGN KEY (`genefam_id`) REFERENCES `genefam` (`genefam_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `gene_history_fk_type_id` FOREIGN KEY (`type_id`) REFERENCES `change_type` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=817247 DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for gene_location
-- ----------------------------
DROP TABLE IF EXISTS `gene_location`;
CREATE TABLE `gene_location` (
  `id` int NOT NULL AUTO_INCREMENT,
  `chr_id` int NOT NULL,
  `start` int DEFAULT NULL,
  `end` int DEFAULT NULL,
  `strand` tinyint DEFAULT NULL,
  `band` varchar(40) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `unique_gene_location` (`chr_id`,`start`,`end`,`strand`,`band`) USING BTREE,
  KEY `gene_location_idx_chr_id` (`chr_id`) USING BTREE,
  CONSTRAINT `gene_location_fk_chr_id` FOREIGN KEY (`chr_id`) REFERENCES `chromosomes` (`chr_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=1668811 DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for gene_note
-- ----------------------------
DROP TABLE IF EXISTS `gene_note`;
CREATE TABLE `gene_note` (
  `id` int NOT NULL AUTO_INCREMENT,
  `note` text CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for gene_status
-- ----------------------------
DROP TABLE IF EXISTS `gene_status`;
CREATE TABLE `gene_status` (
  `id` int NOT NULL AUTO_INCREMENT,
  `status` varchar(45) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `display` varchar(128) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for genefam
-- ----------------------------
DROP TABLE IF EXISTS `genefam`;
CREATE TABLE `genefam` (
  `genefam_id` int NOT NULL AUTO_INCREMENT,
  `taxon_id` int NOT NULL,
  `assigned_id` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL DEFAULT '',
  `assigned_symbol` varchar(45) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `assigned_name` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `status_id` int NOT NULL,
  `editor_id` int NOT NULL,
  `hcop_support_level` int DEFAULT NULL,
  `submitted_date` date NOT NULL DEFAULT (curdate()),
  `modified_date` date NOT NULL DEFAULT (curdate()),
  `approved_date` date DEFAULT NULL,
  PRIMARY KEY (`genefam_id`) USING BTREE,
  UNIQUE KEY `unique_id` (`assigned_id`) USING BTREE,
  UNIQUE KEY `unique_genefam` (`taxon_id`,`assigned_symbol`) USING BTREE,
  KEY `genefam_idx_editor_id` (`editor_id`) USING BTREE,
  KEY `genefam_idx_status_id` (`status_id`) USING BTREE,
  KEY `genefam_idx_assigned_symbol` (`assigned_symbol`) USING BTREE,
  CONSTRAINT `genefam_fk_editor_id` FOREIGN KEY (`editor_id`) REFERENCES `editor` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `genefam_fk_status_id` FOREIGN KEY (`status_id`) REFERENCES `gene_status` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=128926 DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for genefam_orthologs
-- ----------------------------
DROP TABLE IF EXISTS `genefam_orthologs`;
CREATE TABLE `genefam_orthologs` (
  `go_id` int NOT NULL AUTO_INCREMENT,
  `genefam_id_a` int DEFAULT NULL,
  `genefam_id_b` int DEFAULT NULL,
  `taxon_a` int NOT NULL,
  `taxon_b` int NOT NULL,
  `db_id_a` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `db_id_b` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `vgnc_a` varchar(28) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `vgnc_b` varchar(28) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `ensembl_a` varchar(128) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `ensembl_b` varchar(128) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `entrez_a` varchar(28) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `entrez_b` varchar(28) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `symbol_a` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `symbol_b` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `symbol_source_a` varchar(128) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `symbol_source_b` varchar(128) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `name_a` text CHARACTER SET latin1 COLLATE latin1_swedish_ci,
  `name_b` text CHARACTER SET latin1 COLLATE latin1_swedish_ci,
  `source_name_a` varchar(128) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `source_name_b` varchar(128) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `locus_type_a` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `locus_type_b` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `locus_source_a` varchar(128) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `locus_source_b` varchar(128) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `class_a` enum('Gene','Approved') CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `class_b` enum('Gene','Approved') CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `chr_a` varchar(128) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `chr_b` varchar(128) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `support` text CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `text_link_a` text CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `text_link_b` text CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `sort_order` int NOT NULL,
  `date_created` date DEFAULT NULL,
  `date_modified` date DEFAULT NULL,
  PRIMARY KEY (`go_id`) USING BTREE,
  UNIQUE KEY `unique_ortholog` (`taxon_b`,`db_id_a`,`db_id_b`,`ensembl_a`,`ensembl_b`,`entrez_a`,`entrez_b`) USING BTREE,
  KEY `genefam_orthologs_idx_genefam_id_b` (`genefam_id_b`) USING BTREE,
  KEY `taxon_b` (`taxon_b`) USING BTREE,
  KEY `symbol_a` (`symbol_a`) USING BTREE,
  KEY `db_id_a` (`db_id_a`) USING BTREE,
  CONSTRAINT `genefam_orthologs_fk_genefam_id_b` FOREIGN KEY (`genefam_id_b`) REFERENCES `genefam` (`genefam_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=127977 DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for hcop_orthologs
-- ----------------------------
DROP TABLE IF EXISTS `hcop_orthologs`;
CREATE TABLE `hcop_orthologs` (
  `ho_id` int NOT NULL AUTO_INCREMENT,
  `taxon_a` int NOT NULL,
  `taxon_b` int NOT NULL,
  `db_id_a` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `db_id_b` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `ensembl_a` varchar(128) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `ensembl_b` varchar(128) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `entrez_a` varchar(28) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `entrez_b` varchar(28) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `symbol_a` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `symbol_b` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `symbol_source_a` varchar(128) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `symbol_source_b` varchar(128) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `name_a` text CHARACTER SET latin1 COLLATE latin1_swedish_ci,
  `name_b` text CHARACTER SET latin1 COLLATE latin1_swedish_ci,
  `source_name_a` varchar(128) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `source_name_b` varchar(128) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `locus_type_a` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `locus_type_b` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `locus_source_a` varchar(128) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `locus_source_b` varchar(128) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `class_a` enum('Gene','Approved') CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `class_b` enum('Gene','Approved') CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `chr_a` varchar(128) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `chr_b` varchar(128) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `support` text CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `text_link_a` text CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `text_link_b` text CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `sort_order` int NOT NULL,
  `date_created` datetime DEFAULT NULL,
  `date_modified` datetime DEFAULT NULL,
  PRIMARY KEY (`ho_id`) USING BTREE,
  KEY `taxon_b` (`taxon_b`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=326887 DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for hgnc
-- ----------------------------
DROP TABLE IF EXISTS `hgnc`;
CREATE TABLE `hgnc` (
  `hgnc_id` varchar(45) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `hgnc_symbol` varchar(28) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `hgnc_name` text CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `hgnc_status` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `locus_type` varchar(45) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `prev_sym` text CHARACTER SET latin1 COLLATE latin1_swedish_ci,
  `prev_name` text CHARACTER SET latin1 COLLATE latin1_swedish_ci,
  `sym_aliases` text CHARACTER SET latin1 COLLATE latin1_swedish_ci,
  `chr_band` varchar(45) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `entrez_gene_id` varchar(28) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `ensembl_id` varchar(28) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `uniprot_id` varchar(28) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `date_mod` date DEFAULT NULL,
  `date_sym_mod` date DEFAULT NULL,
  `date_name_mod` date DEFAULT NULL,
  `sym_human_only` tinyint(1) DEFAULT NULL,
  `name_human_only` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`hgnc_id`) USING BTREE,
  KEY `h_ens_idx` (`ensembl_id`) USING BTREE,
  KEY `h_eg_idx` (`entrez_gene_id`) USING BTREE,
  KEY `h_sym_idx` (`hgnc_symbol`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for hierarchy
-- ----------------------------
DROP TABLE IF EXISTS `hierarchy`;
CREATE TABLE `hierarchy` (
  `parent_fam_id` int NOT NULL,
  `child_fam_id` int NOT NULL,
  PRIMARY KEY (`parent_fam_id`,`child_fam_id`) USING BTREE,
  KEY `hierarchy_idx_child_fam_id` (`child_fam_id`) USING BTREE,
  KEY `hierarchy_idx_parent_fam_id` (`parent_fam_id`) USING BTREE,
  CONSTRAINT `hierarchy_fk_child_fam_id` FOREIGN KEY (`child_fam_id`) REFERENCES `family_new` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `hierarchy_fk_parent_fam_id` FOREIGN KEY (`parent_fam_id`) REFERENCES `family_new` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for hierarchy_closure
-- ----------------------------
DROP TABLE IF EXISTS `hierarchy_closure`;
CREATE TABLE `hierarchy_closure` (
  `parent_fam_id` int NOT NULL,
  `child_fam_id` int NOT NULL,
  `distance` int DEFAULT NULL,
  PRIMARY KEY (`parent_fam_id`,`child_fam_id`) USING BTREE,
  KEY `hierarchy_closure_idx_child_fam_id` (`child_fam_id`) USING BTREE,
  KEY `hierarchy_closure_idx_parent_fam_id` (`parent_fam_id`) USING BTREE,
  CONSTRAINT `hierarchy_closure_fk_child_fam_id` FOREIGN KEY (`child_fam_id`) REFERENCES `family_new` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `hierarchy_closure_fk_parent_fam_id` FOREIGN KEY (`parent_fam_id`) REFERENCES `family_new` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for icons
-- ----------------------------
DROP TABLE IF EXISTS `icons`;
CREATE TABLE `icons` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(128) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `location` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `class` varchar(128) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for link_has_icon
-- ----------------------------
DROP TABLE IF EXISTS `link_has_icon`;
CREATE TABLE `link_has_icon` (
  `database_resource_id` int NOT NULL,
  `icon_id` int NOT NULL,
  PRIMARY KEY (`database_resource_id`,`icon_id`) USING BTREE,
  KEY `link_has_icon_idx_icon_id` (`icon_id`) USING BTREE,
  CONSTRAINT `link_has_icon_fk_icon_id` FOREIGN KEY (`icon_id`) REFERENCES `icons` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for locus_group
-- ----------------------------
DROP TABLE IF EXISTS `locus_group`;
CREATE TABLE `locus_group` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(45) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for locus_type
-- ----------------------------
DROP TABLE IF EXISTS `locus_type`;
CREATE TABLE `locus_type` (
  `id` int NOT NULL AUTO_INCREMENT,
  `type` varchar(45) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `locus_group_id` int NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `locus_type_idx_locus_group_id` (`locus_group_id`) USING BTREE,
  CONSTRAINT `locus_type_fk_locus_group_id` FOREIGN KEY (`locus_group_id`) REFERENCES `locus_group` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=30 DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for ncbi_gene
-- ----------------------------
DROP TABLE IF EXISTS `ncbi_gene`;
CREATE TABLE `ncbi_gene` (
  `ng_id` int NOT NULL AUTO_INCREMENT,
  `taxon_id` int NOT NULL,
  `gene_id` varchar(28) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `symbol` varchar(128) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `locus_tag` varchar(128) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `chromosome` varchar(25) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `map_location` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `description` text CHARACTER SET latin1 COLLATE latin1_swedish_ci,
  `gene_type` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `symbol_from_nomenclature` varchar(128) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `modification_date` date DEFAULT NULL,
  PRIMARY KEY (`ng_id`) USING BTREE,
  UNIQUE KEY `gene_id` (`gene_id`) USING BTREE,
  KEY `ng_ngi_idx` (`gene_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=547581 DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for nomenclature_type
-- ----------------------------
DROP TABLE IF EXISTS `nomenclature_type`;
CREATE TABLE `nomenclature_type` (
  `id` int NOT NULL AUTO_INCREMENT,
  `type` varchar(45) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for release_date
-- ----------------------------
DROP TABLE IF EXISTS `release_date`;
CREATE TABLE `release_date` (
  `id` int NOT NULL AUTO_INCREMENT,
  `date` date NOT NULL,
  `successful` tinyint NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `release_date_date_index` (`date`) USING BTREE,
  KEY `release_date_successful_index` (`successful`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=43 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------
-- Table structure for sequence
-- ----------------------------
DROP TABLE IF EXISTS `sequence`;
CREATE TABLE `sequence` (
  `id` int NOT NULL AUTO_INCREMENT,
  `sequence` text CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `sequence_type_id` int NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `sequence_idx_sequence_type_id` (`sequence_type_id`) USING BTREE,
  CONSTRAINT `sequence_fk_sequence_type_id` FOREIGN KEY (`sequence_type_id`) REFERENCES `sequence_type` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=3168 DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for sequence_type
-- ----------------------------
DROP TABLE IF EXISTS `sequence_type`;
CREATE TABLE `sequence_type` (
  `id` int NOT NULL AUTO_INCREMENT,
  `type` varchar(45) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for specialist
-- ----------------------------
DROP TABLE IF EXISTS `specialist`;
CREATE TABLE `specialist` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL DEFAULT '',
  `address` text CHARACTER SET latin1 COLLATE latin1_swedish_ci,
  `url` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `unique_specialist` (`name`) USING BTREE,
  KEY `s_name_idx` (`name`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for species
-- ----------------------------
DROP TABLE IF EXISTS `species`;
CREATE TABLE `species` (
  `taxon_id` int NOT NULL,
  `genefam_prefix` varchar(11) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL DEFAULT '',
  `primary_db_table` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `display_name` varchar(128) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `ensembl_species_name` varchar(128) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `is_live` enum('Y','N','C','T','F') CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT 'T',
  `created` datetime NOT NULL,
  PRIMARY KEY (`taxon_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
-- Table structure for xref
-- ----------------------------
DROP TABLE IF EXISTS `xref`;
CREATE TABLE `xref` (
  `id` int NOT NULL AUTO_INCREMENT,
  `external_db_id` int NOT NULL,
  `xref` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `status` enum('Current','Retired','Inactive','ExternalReviewed','ExternalUnreviewed') CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL DEFAULT 'Current',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `unique_xref` (`external_db_id`,`xref`) USING BTREE,
  KEY `xref_idx_external_db_id` (`external_db_id`) USING BTREE,
  KEY `x_xref_idx` (`xref`) USING BTREE,
  CONSTRAINT `xref_fk_external_db_id` FOREIGN KEY (`external_db_id`) REFERENCES `database_resource` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=1163764 DEFAULT CHARSET=latin1;

-- ============================================================
-- Self-contained seed data for gene SELENOF (genefam_id = 4)
-- ============================================================

-- 1. Base lookup tables (required by foreign keys)
INSERT IGNORE INTO `species` (`taxon_id`, `genefam_prefix`, `primary_db_table`, `display_name`, `ensembl_species_name`, `is_live`, `created`)
VALUES (9598, 'VGNC', NULL, 'Chimpanzee', 'ptroglodytes', 'Y', NOW());

INSERT IGNORE INTO `editor` (`id`, `display_name`, `first_name`, `last_name`, `email`, `password`, `current`, `connected`, `jwt_refresh`)
VALUES
(4,  'VGNC Curator',  'Curator', 'Four',  NULL, NULL, 1, 1, NULL),
(6,  'VGNC Curator 6','Curator','Six',   NULL, NULL, 1, 1, NULL),
(10, 'VGNC Curator 10','Curator','Ten',  NULL, NULL, 1, 1, NULL);

INSERT IGNORE INTO `gene_status` (`id`, `status`, `display`) VALUES (6, 'Approved', 'Approved');

INSERT IGNORE INTO `locus_group` (`id`, `name`) VALUES (1, 'protein-coding');  -- id=1 is likely correct
INSERT IGNORE INTO `locus_type` (`id`, `type`, `locus_group_id`) VALUES (2, 'gene with protein product', 1);

INSERT IGNORE INTO `flag_class` (`id`, `class`) VALUES (3, 'evidence level changed');

-- Database resources (the ones used by xrefs)
INSERT IGNORE INTO `database_resource` (`id`, `db_name`, `db_display_name`, `url`, `external_link_template`, `priority`, `class`) VALUES
(1,  'ensembl_gene',           'Ensembl Gene',           NULL, NULL, NULL, NULL),
(2,  'ncbi_gene',              'NCBI Gene',              NULL, NULL, NULL, NULL),
(3,  'ensembl_hcop',           'Ensembl HCOP',           NULL, NULL, NULL, NULL),
(5,  'homologene_hcop',        'HomoloGene HCOP',        NULL, NULL, NULL, NULL),
(7,  'ncbi_hcop',              'NCBI HCOP',              NULL, NULL, NULL, NULL),
(8,  'oma_hcop',               'OMA HCOP',               NULL, NULL, NULL, NULL),
(11, 'panther_hcop',           'Panther HCOP',           NULL, NULL, NULL, NULL);

-- 2. Chromosomes (needed for gene locations)
INSERT IGNORE INTO `chromosomes` (`chr_id`, `taxon_id`, `display_name`, `coord_system`, `refseq_accession`, `genbank_accession`, `ensembl_accession`, `type`, `assigned_to`)
VALUES
(1,      9598, '1', 'chromosome', 'NC_006468.3', 'CM000314.2', NULL, 'Primary Assembly', 4),
(21,     9598, '7', 'chromosome', 'NC_006474.3', 'CM000321.3', NULL, 'Primary Assembly', 6),
(100906, 9598, '7', 'chromosome', 'NC_036886.1', 'CM009245.2', NULL, 'Primary Assembly', 6),
(402814, 9598, '7', 'chromosome', 'NC_072405.1', 'CM054441.1', NULL, 'Primary Assembly', 10);

-- 3. Assemblies (needed by gene_has_location)
INSERT IGNORE INTO `assembly` (`id`, `taxon_id`, `source`, `name`, `genbank_assembly_accession`, `refseq_assembly_accession`, `is_current`, `is_vgnc_default`)
VALUES
(3,   9598, 'NCBI', 'Pan_tro_3.0',                        'GCA_000001515.5', 'GCF_000001515.7', 0, 1),
(27,  9598, 'NCBI', 'Clint_PTRv2',                        'GCA_002880755.3', 'GCF_002880755.1', 0, 0),
(104, 9598, 'NCBI', 'NHGRI_mPanTro3-v1.1-hic.freeze_pri', 'GCA_028858775.1', 'GCF_028858775.1', 0, 0);

-- 4. Assembly ↔ Chromosome links
INSERT IGNORE INTO `assembly_has_chr` (`assembly_id`, `chr_id`)
VALUES
(3, 1),
(3, 21),
(27, 100906),
(104, 402814);

-- 5. Gene locations (coordinate rows)
INSERT IGNORE INTO `gene_location` (`id`, `chr_id`, `start`, `end`, `strand`, `band`)
VALUES
(83797,   1,      87282624, 87332561, -1, NULL),
(200784,  21,     54172730, 54180496, -1, NULL),
(571816,  100906, 54991905, 54999687, -1, NULL),
(1531967, 402814, 58166537, 58173606, -1, NULL);

-- 6. Cross-references (xrefs)
INSERT IGNORE INTO `xref` (`id`, `external_db_id`, `xref`, `status`)
VALUES
(15,      1,  'ENSPTRG00000046631', 'Current'),
(16,      2,  '456995',             'Current'),
(18,      5,  '3145',               'Current'),
(21,      7,  '456995',             'Current'),
(493933,  3,  'ENSPTRG00000046631', 'Retired'),
(493934,  8,  'PANTR21520',         'Current'),
(1148350, 11, 'PANTR|Ensembl=ENSPTRG00000046631|UniProtKB=A0A2I3RY83', 'Current');

-- 7. Gene flags
INSERT IGNORE INTO `gene_flag` (`id`, `type`, `flag_class_id`) VALUES
(16, 'decreased', 3),
(17, 'increased', 3);

-- ============================================================
-- 8. The gene itself
-- ============================================================
INSERT IGNORE INTO `genefam` (`genefam_id`, `taxon_id`, `assigned_id`, `assigned_symbol`, `assigned_name`, `status_id`, `editor_id`, `hcop_support_level`, `submitted_date`, `modified_date`, `approved_date`)
VALUES (4, 9598, 'VGNC:14526', 'SELENOF', 'selenoprotein F', 6, 4, 4, '2015-11-04', '2018-03-02', '2016-09-27');

-- 9. All junction tables
INSERT IGNORE INTO `gene_has_species`       (`genefam_id`, `taxon_id`) VALUES (4, 9598);
INSERT IGNORE INTO `gene_has_locus_type`    (`genefam_id`, `locus_type_id`) VALUES (4, 2);

-- Gene ↔ Locations
INSERT IGNORE INTO `gene_has_location` (`gene_id`, `source`, `location_id`, `assembly_id`) VALUES
(4, 'HCOP', 83797,   3),
(4, 'NCBI', 200784,  3),
(4, 'NCBI', 571816,  27),
(4, 'NCBI', 1531967, 104);

-- Gene ↔ Xrefs
INSERT IGNORE INTO `gene_has_xrefs` (`genefam_id`, `xref_id`, `created_by`, `curated`, `created`, `modified`) VALUES
(4, 15,      1, 1, '2015-11-04', '2016-09-27'),
(4, 16,      1, 1, '2015-11-04', '2016-09-27'),
(4, 18,      1, 0, '2015-11-04', '2015-11-04'),
(4, 21,      1, 0, '2015-11-04', '2015-11-04'),
(4, 493933,  1, 0, '2018-10-04', '2018-10-04'),
(4, 493934,  1, 0, '2018-10-04', '2018-10-04'),
(4, 1148350, 1, 0, '2022-03-27', '2022-03-27');

-- Gene ↔ Flags
INSERT IGNORE INTO `gene_has_flag` (`genefam_id`, `flag_id`) VALUES (4, 16), (4, 17);

-- Ortholog (chimpanzee ↔ human)
INSERT IGNORE INTO `genefam_orthologs`
(`go_id`, `genefam_id_a`, `genefam_id_b`, `taxon_a`, `taxon_b`, `db_id_a`, `db_id_b`,
 `vgnc_a`, `vgnc_b`, `ensembl_a`, `ensembl_b`, `entrez_a`, `entrez_b`,
 `symbol_a`, `symbol_b`, `symbol_source_a`, `symbol_source_b`,
 `name_a`, `name_b`, `source_name_a`, `source_name_b`,
 `locus_type_a`, `locus_type_b`, `locus_source_a`, `locus_source_b`,
 `class_a`, `class_b`, `chr_a`, `chr_b`,
 `support`, `text_link_a`, `text_link_b`, `sort_order`, `date_created`, `date_modified`)
VALUES
(3, NULL, 4, 9606, 9598, 'HGNC:17705', 'VGNC:14526',
 NULL, 'VGNC:14526', 'ENSG00000183291', 'ENSPTRG00000046631', '9403', '456995',
 'SELENOF', 'SELENOF', 'HGNC', 'VGNC',
 'selenoprotein F', 'selenoprotein F', 'HGNC', 'VGNC',
 'gene with protein product', 'gene with protein product', 'HGNC', 'VGNC',
 'Approved', 'Approved', '1p22.3', '1',
 'Ensembl,HomoloGene,NCBI,OMA,Panther',
 'ENSG00000183291,3145,9403,HUMAN50646,HUMAN|HGNC=17705|UniProtKB=O60613',
 'ENSPTRG00000046631,3145,456995,PANTR21520,PANTR|Ensembl=ENSPTRG00000046631|UniProtKB=A0A2I3RY83',
 25546, '2015-11-04', '2023-09-10');
 
SET FOREIGN_KEY_CHECKS = 1;
