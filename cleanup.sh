#!/bin/bash

# Définir la capacité totale et le système de fichiers pour le stockage
CAPACITY=90
FILESYSTEM=/mnt/NAS/

# Configurer Radarr
RADARR=http://localhost:7878
RADARR_KEY=**************

# Configurer Sonarr
SONARR=http://localhost:8989/api/series
SONARR_KEY=**************

# Récupérer les chemins de fichiers de toutes les séries terminées, telles que surveillées par Sonarr
ended_series_paths=$(curl --silent $SONARR -X GET -H "X-Api-Key: $SONARR_KEY" | jq -r '.[] | select(.status == "ended") | .path')

# Récupérer les IDs de tous les films non surveillés tels que suivis par Radarr
unmonitored_movies_ids=$(curl --silent $RADARR/api/v3/movie -X GET -H "X-Api-Key: $RADARR_KEY" | jq '.[] | select(.monitored == false) | .id')

# Récupérer les identifiants de toutes les séries non surveillées telles que suivies par Sonarr
unmonitored_series_ids=$(curl --silent $SONARR -X GET -H "X-Api-Key: $SONARR_KEY" | jq '.[] | select(.monitored == false) | .id')

#-------------------------------------------------------------------

if [ $(df -P $FILESYSTEM | awk '{gsub("%",""); capacity = $5}; END {print capacity}') -gt $CAPACITY ]; then
  # Itérer à travers tous les fichiers dans la variable `ended_series_paths`
  while read -r file; do
    # Vérifier si le fichier est plus vieux que 180 jours
    if [ ! $(find "$file" -mtime -180 | wc -l) -gt 0 ]; then
      # Supprimer le fichier s'il est plus vieux que 180 jours
      rm -rf "$file"
    fi
  done <<< "$ended_series_paths"
  # Trouver tous les répertoires dans/mnt/NAS/Films/ qui sont plus vieux que 90 jours et les supprimer
  find /mnt/NAS/Films/ -type d -mtime +90 -exec rm -rf {} \;
fi

#-------------------------------------------------------------------

# Itérer à travers la liste des identifiants de séries non surveillés
for id in $unmonitored_series_ids; do
  # Envoyer une demande DELETE à l'API Sonarr pour chaque identifiant
  curl --silent $SONARR/$id -X DELETE -H "X-Api-Key: $SONARR_KEY"
done

#-------------------------------------------------------------------

# Itérer à travers la liste des identifiants de films non surveillés
for id in $unmonitored_movies_ids; do
  # Envoyer une demande DELETE à l'API Radarr pour chaque identifiant
  curl --silent $RADARR/api/v3/movie/$id -X DELETE -H "X-Api-Key: $RADARR_KEY"
done
