# === Variables ===
$org        = "your-org"
$project    = "your-project"
$wikiId     = "your-wiki"
$pagePath   = "/<WIKI_PATH>/<WIKI_PAGE.md>"   # single page for PoC
$pat        = "$(System.AccessToken)" # or pipeline secret
$hiveUrl    = "https://thehive.example.com/api/v1/caseTemplate/~templateId"
$hiveApiKey = "$(TheHiveApiKey)"      # pipeline secret

# === Auth Headers ===
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$pat"))
$headers = @{ Authorization = "Basic $base64AuthInfo" }

# === Step 1: Fetch Wiki Page ===
$wikiUrl = "https://dev.azure.com/$org/$project/_apis/wiki/wikis/$wikiId/pages?path=$pagePath&includeContent=true&api-version=7.1-preview.1"
$response = Invoke-RestMethod -Uri $wikiUrl -Headers $headers -Method Get
$markdown = $response.content

# === Step 2: Build TheHive Payload ===
$body = @{
    description = "Synced from Azure DevOps Wiki page: $pagePath"
    tasks       = @(
        @{
            title       = "Playbook Steps"
            description = $markdown
        }
    )
} | ConvertTo-Json -Depth 5

# === Step 3: Push to TheHive ===
$hiveHeaders = @{
    Authorization = "Bearer $hiveApiKey"
    "Content-Type" = "application/json"
}

Invoke-RestMethod -Uri $hiveUrl -Method Patch -Headers $hiveHeaders -Body $body