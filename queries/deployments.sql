# Deployments Table

WITH deploys_cloudbuild_github_gitlab AS (# Cloud Build, Github, Gitlab pipelines
      SELECT
      JSON_EXTRACT(metadata, '$.issue.label') as team,
      source,
      id as deploy_id,
      time_created,
      CASE WHEN source = "cloud_build" then JSON_EXTRACT_SCALAR(metadata, '$.substitutions.COMMIT_SHA')
           WHEN source like "github%" then JSON_EXTRACT_SCALAR(metadata, '$.pull_request.merge_commit_sha')
           end as main_commit,
      CASE WHEN source LIKE "github%" THEN ARRAY(
                SELECT JSON_EXTRACT_SCALAR(string_element, '$')
                FROM UNNEST(JSON_EXTRACT_ARRAY(metadata, '$.deployment.additional_sha')) AS string_element)
           ELSE ARRAY<string>[] end as additional_commits
      FROM four_keys.events_raw 
      WHERE (
      # Cloud Build Deployments
         (source = "cloud_build" AND JSON_EXTRACT_SCALAR(metadata, '$.status') = "SUCCESS")
      # GitHub Deployments
      # OR (source LIKE "github%" and event_type = "deployment_status" and JSON_EXTRACT_SCALAR(metadata, '$.deployment_status.state') = "success")
      OR (source LIKE "github%" and event_type = "pull_request" and JSON_EXTRACT_SCALAR(metadata, '$.pull_request.merged') = 'true' and JSON_EXTRACT_SCALAR(metadata, '$.pull_request.base.ref') = "master" and JSON_EXTRACT_SCALAR(metadata, '$.action') = "closed")
      )
    ),
    deploys AS (
      SELECT * FROM
      deploys_cloudbuild_github_gitlab
    ),
    changes_raw AS (
      SELECT
      id,
      metadata as change_metadata
      FROM four_keys.events_raw
    ),
    deployment_changes as (
      SELECT
      source,
      deploy_id,
      deploys.time_created time_created,
      change_metadata,
      four_keys.json2array(JSON_EXTRACT(change_metadata, '$.commits')) as array_commits,
      main_commit,
      team
      FROM deploys
      JOIN
        changes_raw on (
          changes_raw.id = deploys.main_commit
          or changes_raw.id in unnest(deploys.additional_commits)
        )
    )

    SELECT 
    source,
    deploy_id,
    time_created,
    main_commit,
    team,
    ARRAY_AGG(DISTINCT JSON_EXTRACT_SCALAR(array_commits, '$.id')) changes,    
    FROM deployment_changes
    CROSS JOIN deployment_changes.array_commits
    GROUP BY 1,2,3,4,5;
