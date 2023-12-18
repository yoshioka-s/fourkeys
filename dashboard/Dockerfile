# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM grafana/grafana

# uncomment these to skip authentication
ENV GF_ROOT_URL https://fourkeys-grafana-dashboard-op4kvbioya-uc.a.run.app/
ENV GF_SERVER_ROOT_URL https://fourkeys-grafana-dashboard-op4kvbioya-uc.a.run.app/

# during setup, this variable will be configured onto the Cloud Run service
# (default here to "US" as a fallback)
ENV BQ_REGION "JA"

# Setting grafana config
COPY grafana.ini /etc/grafana

# Provisioning dashboards and datasources
COPY fourkeys_dashboard.json /etc/grafana/dashboards/
COPY nexta_dashboard.json /etc/grafana/nexta/
COPY dashboards.yaml /etc/grafana/provisioning/dashboards
COPY datasource.yaml /etc/grafana/provisioning/datasources

# Installing the BigQuery Plugin
RUN grafana-cli plugins install grafana-bigquery-datasource
