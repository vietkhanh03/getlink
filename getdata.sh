#!/bin/bash

# Global variables for MySQL credentials and output file
DB_HOST="172.16.2.80"
DB_USER="root"
DB_PASS="root"
OUTPUT_FILE="output.csv"
#DATABASES=("idesk_bmt" "idesk_cumgar" "idesk_gtvt" "idesk_khcn" "idesk_krongbong" "idesk_ngoaivu" "idesk_thanhtra" "idesk_tuphap" "idesk_vhttdl")
#DATABASES=("idesk_krongnang" "idesk_madrak" "idesk_buondon" "idesk_eakar" "idesk_cukuin" "idesk_lak")
#DATABASES=("idesk_nnptnt" "idesk_vpubnd" "idesk_yte")
#DATABASES=("idesk_buonho" "idesk_easup" "idesk_eahleo" "idesk_krongana" "idesk_krongbuk" "idesk_krongpak" "idesk_tnmt")
#DATABASES=("idesk_bqldadtxd" "idesk_bqldagtnn" "idesk_cddl" "idesk_dantoc" "idesk_gddt")
#DATABASES=("idesk_bqlkcn" "idesk_congthuong" "idesk_khdt" "idesk_ldtbxh" "idesk_vphdnd" "idesk_tttt")
#DATABASES=("idesk_noivu" "idesk_taichinh" "idesk_xaydung")
#DATABASES=("idesk_drt" "idesk_haiquan" "idesk_hlhpn" "idesk_lhhkhkt" "idesk_tinhdoan" "idesk_kbnn" "idesk_lmhtx" "idesk_hvhnt" "idesk_bmtu" "idesk_hoinhabao")
DATABASES=("idesk_hctd" "idesk_qdtpt" "idesk_cdytdl" "idesk_cdkt" "idesk_cdvhnt" "idesk_lhctchn" "idesk_hdy" "idesk_congan" "idesk_daotao" "idesk_bchqs")
# Function to execute MySQL query and export to CSV
export_to_csv() {
    local db=$1
    local year=$2
    local query
    local query_result
    query=$(printf "SELECT '%s' AS database_name, u.code, u.name, re.type, COUNT(re.id) AS count, %d AS year
                    FROM re_record re
                    INNER JOIN adm_unit u ON re.unit_code = u.unit_code
                    WHERE re.sta_d IS NOT NULL AND YEAR(re.sta_d) = %d
                    GROUP BY u.code, u.name, re.type;" "$db" "$year" "$year")
    query_result=$(mysql --host="$DB_HOST" --user="$DB_USER" --password="$DB_PASS" --database="$db" --execute="$query" --default-character-set=utf8mb4 --batch --silent --skip-column-names 2>&1)
    if [[ $? -ne 0 ]]; then
        printf "Error executing query for database %s, year %d: %s\n" "$db" "$year" "$query_result" >&2
        return 1
    fi
    # Append result to output file
    printf "%s\n" "$query_result" >> "$OUTPUT_FILE"
}

# Main function to orchestrate the script
main() {
    if [[ -z "$DB_HOST" || -z "$DB_USER" || -z "$DB_PASS" || -z "$OUTPUT_FILE" || ${#DATABASES[@]} -eq 0 ]]; then
        printf "Missing required environment variables.\n" >&2
        return 1
    fi

    # Create or truncate the output file
    : > "$OUTPUT_FILE"

    # Add header to CSV
    printf "database_name,code,name,type,count,year\n" > "$OUTPUT_FILE"

    for db in "${DATABASES[@]}"; do
        for year in 2021 2022 2023 2024; do
            export_to_csv "$db" "$year"
            if [[ $? -ne 0 ]]; then
                printf "Failed to export data to CSV for database %s, year %d.\n" "$db" "$year" >&2
                return 1
            fi
        done
    done

    printf "Data successfully exported to %s\n" "$OUTPUT_FILE"
}

# Execute the main function
main
