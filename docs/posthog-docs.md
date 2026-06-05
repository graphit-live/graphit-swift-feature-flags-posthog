---
title: "API Feature Flags installation - Docs"
site: "PostHog"
source: "https://posthog.com/docs/feature-flags/installation/api"
domain: "posthog.com"
description: "The single platform for engineers to analyze, test, observe, and deploy new features. Product analytics, session replay, feature flags, experiments, CDP, and more."
word_count: 382
---

## API Feature Flags installation

1. 1
	## Evaluate the feature flag value using flags
	Required
	`flags` is the endpoint used to determine if a given flag is enabled for a certain user or not.
	```bash
	curl -v -L --header "Content-Type: application/json" -d '{
	    "token": "<ph_project_token>",
	    "distinct_id": "distinct_id_of_your_user",
	    "groups" : {
	        "group_type": "group_id"
	    }
	}' "https://us.i.posthog.com/flags?v=2"
	```
	**Note:** The `groups` key is only required for group-based feature flags. If you use it, replace `group_type` and `group_id` with the values for your group such as `company: "Twitter"`.
2. 2
	## Include feature flag information when capturing events
	Required
	If you want to use your feature flag to breakdown or filter events in your insights, you'll need to include feature flag information in those events. This ensures that the feature flag value is attributed correctly to the event.
	**Note:** This step is only required for events captured using our server-side SDKs or API.
	```bash
	curl -v -L --header "Content-Type: application/json" -d '{
	    "token": "<ph_project_token>",
	    "event": "your_event_name",
	    "distinct_id": "distinct_id_of_your_user",
	    "properties": {
	        "$feature/feature-flag-key": "variant-key"
	    }
	}' https://us.i.posthog.com/i/v0/e/
	```
3. 3
	## Send a $feature\_flag\_called event
	Optional
	To track usage of your feature flag and view related analytics in PostHog, submit the `$feature_flag_called` event whenever you check a feature flag value in your code.
	You need to include two properties with this event:
	1. `$feature_flag_response`: This is the name of the variant the user has been assigned to e.g., "control" or "test"
	2. `$feature_flag`: This is the key of the feature flag in your experiment.
	```bash
	curl -v -L --header "Content-Type: application/json" -d '{
	    "token": "<ph_project_token>",
	    "event": "$feature_flag_called",
	    "distinct_id": "distinct_id_of_your_user",
	    "properties": {
	        "$feature_flag": "feature-flag-key",
	        "$feature_flag_response": "variant-name"
	    }
	}' https://us.i.posthog.com/i/v0/e/
	```
4. 4
	## Running experiments
	Optional
	Experiments run on top of our feature flags. Once you've implemented the flag in your code, you run an experiment by creating a new experiment in the PostHog dashboard.
5. 5
	## Next steps
	Recommended
	Now that you're evaluating flags, continue with the resources below to learn what else Feature Flags enables within the PostHog platform.
	| Resource | Description |
	| --- | --- |
	| [Creating a feature flag](https://posthog.com/docs/feature-flags/creating-feature-flags) | How to create a feature flag in PostHog |
	| [Adding feature flag code](https://posthog.com/docs/feature-flags/adding-feature-flag-code) | How to check flags in your code for all platforms |
	| [Framework-specific guides](https://posthog.com/docs/feature-flags/tutorials#framework-guides) | Setup guides for React Native, Next.js, Flutter, and other frameworks |
	| [How to do a phased rollout](https://posthog.com/tutorials/phased-rollout) | Gradually roll out features to minimize risk |
	| [More tutorials](https://posthog.com/docs/feature-flags/tutorials) | Other real-world examples and use cases |


---
title: "Flags – the feature flags evaluation API endpoint - Docs"
site: "PostHog"
source: "https://posthog.com/docs/api/flags"
domain: "posthog.com"
description: "The  flags  endpoint is used to evaluate feature flags for a given  distinct_id . This means it is the main endpoint not only for feature flags, but…"
word_count: 1770
---

## Flags – the feature flags evaluation API endpoint

The `flags` endpoint is used to evaluate feature flags for a given `distinct_id`. This means it is the main endpoint not only for feature flags, but also experimentation, early access features, and survey display conditions.

It is a POST-only public endpoint that uses your [project token](https://app.posthog.com/project/settings) and does not return any sensitive data from your PostHog instance.

> **Note:** Make sure to send API requests to the correct domain. These are `https://us.i.posthog.com` for US Cloud, `https://eu.i.posthog.com` for EU Cloud, and your self-hosted domain for self-hosted instances. Confirm yours by checking your URL from your PostHog instance.

There are 3 steps to implement feature flags using the PostHog API:

### Step 1: Evaluate the feature flag value using flags

`flags` is the endpoint used to determine if a given flag is enabled for a certain user or not.

#### Request

```shell
# Basic request (flags only)
curl -v -L --header "Content-Type: application/json" -d '  {
    "api_key": "<ph_project_token>",
    "distinct_id": "distinct_id_of_your_user",
    "groups" : {
        "group_type": "group_id"
    }
}' "https://us.i.posthog.com/flags?v=2"

# With configuration (flags + PostHog config)
curl -v -L --header "Content-Type: application/json" -d '  {
    "api_key": "<ph_project_token>",
    "distinct_id": "distinct_id_of_your_user",
    "groups" : {
        "group_type": "group_id"
    }
}' "https://us.i.posthog.com/flags?v=2&config=true"
```

> **Note:** The `groups` key is only required for group-based feature flags. If you use it, replace `group_type` and `group_id` with the values for your group such as `company: "Twitter"`.

#### Using evaluation context tags and runtime filtering without SDKs

When making direct API calls to the `/flags` endpoint, you can control which flags are evaluated using evaluation context tags and runtime filtering.

##### Evaluation contexts

To filter flags by evaluation context, include the `evaluation_contexts` field in your request body:

> **Note:** The legacy parameter `evaluation_environments` is also supported for backward compatibility.

```shell
curl -v -L --header "Content-Type: application/json" -d '  {
    "api_key": "<ph_project_token>",
    "distinct_id": "distinct_id_of_your_user",
    "evaluation_contexts": ["production", "web"]
}' "https://us.i.posthog.com/flags?v=2"
```

Only flags where at least one evaluation tag matches (or flags with no tags at all) will be returned. For example:

- Flag with evaluation context tags `["production", "api", "backend"]` + request with `["production", "web"]` = ✅ Flag evaluates ("production" matches)
- Flag with evaluation context tags `["staging", "api"]` + request with `["production", "web"]` = ❌ Flag doesn't evaluate (no tags match)
- Flag with evaluation context tags `["web", "mobile"]` + request with `["production", "web"]` = ✅ Flag evaluates ("web" matches)
- Flag with no evaluation context tags = ✅ Always evaluates (backward compatibility)

##### Runtime detection

Evaluation runtime (server vs. client) is automatically detected based on your request headers and user-agent. This determines which flags are available based on their runtime setting (server-only, client-only, or all).

**How runtime is detected:**

1. **User-Agent patterns** - The system analyzes the User-Agent header:
	- **Client-side patterns**: `Mozilla/`, `Chrome/`, `Safari/`, `Firefox/`, `Edge/` (browsers), or mobile SDKs like `posthog-android/`, `posthog-ios/`, `posthog-react-native/`, `posthog-flutter/`
		- **Server-side patterns**: `posthog-python/`, `posthog-ruby/`, `posthog-php/`, `posthog-java/`, `posthog-go/`, `posthog-node/`, `posthog-dotnet/`, `posthog-elixir/`, `python-requests/`, `curl/`
2. **Browser-specific headers** - Presence of these headers indicates client-side:
	- `Origin` header
		- `Referer` header
		- `Sec-Fetch-Mode` header
		- `Sec-Fetch-Site` header
3. **Default behavior** - If runtime can't be determined, the system includes flags with no runtime requirement and those set to "all"

**Examples of runtime detection:**

```javascript
// Browser fetch - Detected as CLIENT runtime
// Will receive: client-only flags + "all" flags
// Won't receive: server-only flags
const response = await fetch("https://us.i.posthog.com/flags?v=2", {
    method: "POST",
    headers: {
        "Content-Type": "application/json",
        // Browser automatically adds Origin, Referer, Sec-Fetch-* headers
    },
    body: JSON.stringify({
        api_key: "<ph_project_token>",
        distinct_id: "user-id"
    })
});
```

```python
# Python requests - Detected as SERVER runtime
# Will receive: server-only flags + "all" flags
# Won't receive: client-only flags
import requests

response = requests.post(
    "https://us.i.posthog.com/flags?v=2",
    json={
        "api_key": "<ph_project_token>",
        "distinct_id": "user-id"
    }
    # python-requests/ in User-Agent indicates server-side
)
```

```shell
# curl - Detected as SERVER runtime
# Will receive: server-only flags + "all" flags
# Won't receive: client-only flags
curl -v -L --header "Content-Type: application/json" -d '{
    "api_key": "<ph_project_token>",
    "distinct_id": "user-id"
}' "https://us.i.posthog.com/flags?v=2"
# curl/ in User-Agent indicates server-side
```

```javascript
// Node.js with custom User-Agent - Control runtime detection
const response = await fetch("https://us.i.posthog.com/flags?v=2", {
    method: "POST",
    headers: {
        "Content-Type": "application/json",
        "User-Agent": "posthog-node/3.0.0"  // Explicitly indicates server-side
    },
    body: JSON.stringify({
        api_key: "<ph_project_token>",
        distinct_id: "user-id"
    })
});
```

##### Combining evaluation context tags and runtime filtering

Both features work together as sequential filters:

```javascript
// Example: Production web client
const response = await fetch("https://us.i.posthog.com/flags?v=2", {
    method: "POST",
    headers: {
        "Content-Type": "application/json",
        // Browser headers will trigger client runtime detection
    },
    body: JSON.stringify({
        api_key: "<ph_project_token>",
        distinct_id: "user-id",
        evaluation_contexts: ["production", "web"]
    })
});

// This request will only receive flags that:
// 1. Have runtime set to "client" OR "all" (due to browser headers)
// AND
// 2. Have evaluation context tags matching "production" OR "web" (or no tags)
// Note: You can also use the legacy "evaluation_environments" parameter
```

This allows precise control over which flags are evaluated in different contexts, helping optimize costs and improve security by ensuring flags only evaluate where intended.

#### Response

The response varies depending on whether you include the `config=true` query parameter:

##### Basic response (/flags?v=2)

Use this endpoint when you only need to evaluate feature flags. It returns a response with just the flag evaluation results.

> **Note:** If a feature flag is associated with an experiment that has a [holdout group](https://posthog.com/docs/experiments/holdouts), users in the holdout receive a variant value in the format `holdout-{holdout_id}` (e.g., `holdout-727`). You can detect holdout users by checking if the variant starts with `holdout-`.

```json
{
  "flags": {
    "my-awesome-flag": {
      "key": "my-awesome-flag", 
      "enabled": true,
      "reason": {
        "code": "condition_match",
        "condition_index": 0,
        "description": "Condition set 1 matched"
      },
      "metadata": {
        "id": 1,
        "version": 1,
        "payload": "{\"example\": \"json\", \"payload\": \"value\"}"
      }
    },
    "my-multivariate-flag" :{
      "key":"my-multivariate-flag",
      "enabled": true,
      "variant": "some-string-value",
      "reason": {
        "code": "condition_match",
        "condition_index": 1,
        "description": "Condition set 2 matched"
      },
      "metadata": {
        "id": 2,
        "version": 42,
      }
    },
    "flag-thats-not-on": {
      "key": "flag-thats-not-on",
      "enabled": false,
      "reason": {
        "code": "no_condition_match",
        "condition_index": 0,
        "description": "No condition sets matched"
      },
      "metadata": {
        "id": 3,
        "version": 1
      }
    }
  },
  "errorsWhileComputingFlags": false,
  "requestId": "550e8400-e29b-41d4-a716-446655440000"
}
```

##### Full response with configuration (/flags?v=2&config=true)

Use this endpoint when you need both feature flag evaluation and PostHog configuration information (useful for client-side SDKs that need to initialize PostHog):

```json
{
  "config": {
    "enable_collect_everything": true
  },
  "toolbarParams": {},
  "errorsWhileComputingFlags": false,
  "isAuthenticated": false,
  "requestId": "550e8400-e29b-41d4-a716-446655440000",
  "supportedCompression": [
    "gzip",
    "lz64"
  ],
  "flags": {
    "my-awesome-flag": {
      "key": "my-awesome-flag", 
      "enabled": true,
      "reason": {
        "code": "condition_match",
        "condition_index": 0,
        "description": "Condition set 1 matched"
      },
      "metadata": {
        "id": 1,
        "version": 1,
        "payload": "{\"example\": \"json\", \"payload\": \"value\"}"
      }
    },
    "my-multivariate-flag" :{
      "key":"my-multivariate-flag",
      "enabled": true,
      "variant": "some-string-value",
      "reason": {
        "code": "condition_match",
        "condition_index": 1,
        "description": "Condition set 2 matched"
      },
      "metadata": {
        "id": 2,
        "version": 42,
      }
    },
    "flag-thats-not-on": {
      "key": "flag-thats-not-on",
      "enabled": false,
      "reason": {
        "code": "no_condition_match",
        "condition_index": 0,
        "description": "No condition sets matched"
      },
      "metadata": {
        "id": 3,
        "version": 1
      }
    }
  }
}
```

> **Note:** `errorsWhileComputingFlags` will return `true` if we didn't manage to compute some flags (for example, if there's an [ongoing incident involving flag evaluation](https://status.posthog.com/)).
> 
> This enables partial updates to currently active flags in your clients.

#### Quota limiting

If your organization exceeds its feature flag quota, the `/flags` endpoint will return a modified response with `quotaLimited`.

For basic response (`/flags?v=2`):

```json
{
  "flags": {},
  "errorsWhileComputingFlags": false,
  "quotaLimited": ["feature_flags"],
  "requestId": "d4d89b14-9619-4627-adf2-01b761691c2e"
}
```

For full response with configuration (`/flags?v=2&config=true`):

```json
{
  "config": {
    "enable_collect_everything": true
  },
  "toolbarParams": {},
  "isAuthenticated": false,
  "supportedCompression": [
    "gzip",
    "lz64"
  ],
  "flags": {},
  "errorsWhileComputingFlags": false,
  "quotaLimited": ["feature_flags"],
  "requestId": "d4d89b14-9619-4627-adf2-01b761691c2e"
  // ... other fields, not relevant to feature flags
}
```

When you receive a response with `quotaLimited` containing `"feature_flags"`, it means:

1. Your feature flag evaluations have been temporarily paused because you've exceeded your feature flag quota
2. If you want to continue evaluating feature flags, you can increase your quota in [your billing settings](https://us.posthog.com/organization/billing) under **Feature flags & Experiments** or [contact support](https://us.posthog.com/#panel=support%3Asupport%3Abilling%3A%3Atrue)

### Step 2: Include feature flag information when capturing events

If you want use your feature flag to breakdown or filter events in your [insights](https://posthog.com/docs/product-analytics/insights), you'll need to include feature flag information in those events. This ensures that the feature flag value is attributed correctly to the event.

> **Note:** This step is only required for events captured using our server-side SDKs or.

To do this, include the `$feature/feature_flag_name` property in your event:

```shell
curl -v -L --header "Content-Type: application/json" -d '  {
    "api_key": "<ph_project_token>",
    "event": "your_event_name",
    "distinct_id": "distinct_id_of_your_user",
    "properties": {
      "$feature/feature-flag-key": "variant-key" # Replace feature-flag-key with your flag key. Replace 'variant-key' with the key of your variant
    }
}' https://us.i.posthog.com/i/v0/e/
```

### Step 3: Send a $feature\_flag\_called event

To track usage of your feature flag and view related analytics in PostHog, submit the `$feature_flag_called` event whenever you check a feature flag value in your code.

You need to include two properties with this event:

1. `$feature_flag_response`: This is the name of the variant the user has been assigned to e.g., "control" or "test"
2. `$feature_flag`: This is the key of the feature flag in your experiment.

```shell
curl -v -L --header "Content-Type: application/json" -d '  {
    "api_key": "<ph_project_token>",
    "event": "$feature_flag_called",
    "distinct_id": "distinct_id_of_your_user",
    "properties": {
      "$feature_flag": "feature-flag-key",
      "$feature_flag_response": "variant-name"
    }
}' https://us.i.posthog.com/i/v0/e/
```

### Advanced: Overriding server properties

Sometimes, you may want to evaluate feature flags using [person properties](https://posthog.com/docs/product-analytics/person-properties), [groups](https://posthog.com/docs/product-analytics/group-analytics), or group properties that haven't been ingested yet, or were set incorrectly earlier.

You can provide properties to evaluate the flag with by using the `person properties`, `groups`, and `group properties` arguments. PostHog will then use these values to evaluate the flag, instead of any properties currently stored on your PostHog server.

For example:

```shell
curl -v -L --header "Content-Type: application/json" -d '  {
    "api_key": "<ph_project_token>",
    "distinct_id": "distinct_id_of_your_user",
    "groups" : { # Required only for group-based feature flags
      "group_type": "group_id" # Replace "group_type" with the name of your group type. Replace "group_id" with the id of your group.
    },
    "person_properties": {"<personProp1>": "<personVal1>"}, # Optional. Include any properties used to calculate the value of the feature flag.
    "group_properties": {"group type": {"<groupProp1>":"<groupVal1>"}} # Optional. Include any properties used to calculate the value of the feature flag.
}' https://us.i.posthog.com/flags?v=2
```

### Overriding GeoIP properties

By default, a user's GeoIP properties are set using the IP address they use to capture events on the frontend. You may want to override the these properties when evaluating feature flags. A common reason to do this is when you're not using PostHog on your frontend, so the user has no GeoIP properties.

To override the GeoIP properties used to evaluate a feature flag, provide an IP address in the `HTTP_X_FORWARDED_FOR` when making your `/flags` request:

```shell
curl -v -L \
--header "Content-Type: application/json" \
--header "HTTP_X_FORWARDED_FOR: the_client_ip_address_to_use " \
-d '  {
    "api_key": "<ph_project_token>",
    "distinct_id": "distinct_id_of_your_user"
}' https://us.i.posthog.com/flags?v=2
```

The list of properties that this overrides:

1. `$geoip_city_name`
2. `$geoip_country_name`
3. `$geoip_country_code`
4. `$geoip_continent_name`
5. `$geoip_continent_code`
6. `$geoip_postal_code`
7. `$geoip_time_zone`

---
title: "Feature flags API Reference"
site: "PostHog"
source: "https://posthog.com/docs/api/feature-flags"
domain: "posthog.com"
description: "The single platform for engineers to analyze, test, observe, and deploy new features. Product analytics, session replay, feature flags, experiments, CDP, and more."
word_count: 2984
---

## Feature flags

> For instructions on how to authenticate to use this endpoint, see [API overview](https://posthog.com/docs/api/overview).

### Endpoints

| `GET` | `/api/projects/:project_id/feature_flags/` |
| --- | --- |
| `POST` | `/api/projects/:project_id/feature_flags/` |
| `GET` | `/api/projects/:project_id/feature_flags/:id/` |
| `PATCH` | `/api/projects/:project_id/feature_flags/:id/` |
| `DELETE` | `/api/projects/:project_id/feature_flags/:id/` |
| `GET` | `/api/projects/:project_id/feature_flags/:id/activity/` |
| `POST` | `/api/projects/:project_id/feature_flags/:id/create_static_cohort_for_flag/` |
| `POST` | `/api/projects/:project_id/feature_flags/:id/dashboard/` |
| `GET` | `/api/projects/:project_id/feature_flags/:id/dependent_flags/` |
| `POST` | `/api/projects/:project_id/feature_flags/:id/enrich_usage_dashboard/` |
| `GET` | `/api/projects/:project_id/feature_flags/:id/remote_config/` |
| `GET` | `/api/projects/:project_id/feature_flags/:id/status/` |
| `POST` | `/api/projects/:project_id/feature_flags/:id/test_evaluation/` |
| `GET` | `/api/projects/:project_id/feature_flags/:id/versions/:version_number/` |
| `GET` | `/api/projects/:project_id/feature_flags/activity/` |
| `POST` | `/api/projects/:project_id/feature_flags/bulk_delete/` |
| `POST` | `/api/projects/:project_id/feature_flags/bulk_keys/` |
| `POST` | `/api/projects/:project_id/feature_flags/bulk_update_tags/` |
| `GET` | `/api/projects/:project_id/feature_flags/evaluation_reasons/` |

[

Next page →

](https://posthog.com/docs/api/feature-flags-2)

## List all feature flags

> Also available via the [PostHog MCP server](https://posthog.com/docs/model-context-protocol):
> 
> - `feature-flag-get-all` — Get all feature flags

This endpoint returns a list of feature flags and their details like `name`, `key`, `variants`, `rollout_percentage`, and more.

To evaluate and determine the value of flags for a given user, use the [`flags` endpoint](https://posthog.com/docs/api/flags) instead.

Create, read, update and delete feature flags. [See docs](https://posthog.com/docs/feature-flags) for more information on feature flags.

If you're looking to use feature flags on your application, you can either use our JavaScript Library or our dedicated endpoint to check if feature flags are enabled for a given user.

#### Required API key scopes

`feature_flag:read`

---

#### Query parameters

- active
	string
	One of: `"STALE"` `"false"` `"true"`
- created\_by\_id
	string
- evaluation\_runtime
	string
	One of: `"both"` `"client"` `"server"`
- excluded\_properties
	string
- has\_evaluation\_contexts
	string
	One of: `"false"` `"true"`
- limit
	integer
- offset
	integer
- search
	string
- tags
	string
- type
	string
	One of: `"boolean"` `"experiment"` `"multivariant"` `"remote_config"`

---

#### Response

#### Example request

`GET ` `/api/projects/:project_id/feature_flags`

```bash
export POSTHOG_PERSONAL_API_KEY=[your personal api key]
curl \
    -H "Authorization: Bearer $POSTHOG_PERSONAL_API_KEY" \
    <ph_app_host>/api/projects/:project_id/feature_flags/
```

#### Example response

##### Status 200

```javascript
{
  "count": 123,
  "next": "http://api.example.org/accounts/?offset=400&limit=100",
  "previous": "http://api.example.org/accounts/?offset=200&limit=100",
  "results": [
    {
      "id": 0,
      "name": "string",
      "key": "string",
      "filters": {},
      "deleted": true,
      "active": true,
      "created_by": {
        "id": 0,
        "uuid": "095be615-a8ad-4c33-8e9c-c7612fbf6c9f",
        "distinct_id": "string",
        "first_name": "string",
        "last_name": "string",
        "email": "user@example.com",
        "is_email_verified": true,
        "hedgehog_config": {},
        "role_at_organization": "engineering"
      },
      "created_at": "2019-08-24T14:15:22Z",
      "updated_at": "2019-08-24T14:15:22Z",
      "version": 0,
      "last_modified_by": {
        "id": 0,
        "uuid": "095be615-a8ad-4c33-8e9c-c7612fbf6c9f",
        "distinct_id": "string",
        "first_name": "string",
        "last_name": "string",
        "email": "user@example.com",
        "is_email_verified": true,
        "hedgehog_config": {},
        "role_at_organization": "engineering"
      },
      "ensure_experience_continuity": true,
      "experiment_set": [
        0
      ],
      "experiment_set_metadata": [
        {}
      ],
      "surveys": {},
      "features": {},
      "rollback_conditions": null,
      "performed_rollback": true,
      "can_edit": true,
      "tags": [
        null
      ],
      "evaluation_contexts": [
        null
      ],
      "usage_dashboard": 0,
      "analytics_dashboards": [
        0
      ],
      "has_enriched_analytics": true,
      "user_access_level": "string",
      "creation_context": "feature_flags",
      "is_remote_configuration": true,
      "has_encrypted_payloads": true,
      "status": "string",
      "evaluation_runtime": "server",
      "bucketing_identifier": "distinct_id",
      "last_called_at": "2019-08-24T14:15:22Z",
      "_create_in_folder": "string",
      "_should_create_usage_dashboard": true,
      "is_used_in_replay_settings": true
    }
  ]
}
```

---

## Create feature flags

> Also available via the [PostHog MCP server](https://posthog.com/docs/model-context-protocol):
> 
> - `create-feature-flag` — Create feature flag

Create, read, update and delete feature flags. [See docs](https://posthog.com/docs/feature-flags) for more information on feature flags.

If you're looking to use feature flags on your application, you can either use our JavaScript Library or our dedicated endpoint to check if feature flags are enabled for a given user.

#### Required API key scopes

`feature_flag:write`

---

#### Request parameters

- key
	string
- name
	string
- filters
- active
	boolean
- tags
	array
- evaluation\_contexts
	array

---

#### Response

#### Example request

`POST ` `/api/projects/:project_id/feature_flags`

```bash
export POSTHOG_PERSONAL_API_KEY=[your personal api key]
curl 
    -H 'Content-Type: application/json'\
    -H "Authorization: Bearer $POSTHOG_PERSONAL_API_KEY" \
    <ph_app_host>/api/projects/:project_id/feature_flags/\
    -d key="string"
```

#### Example response

##### Status 201

```javascript
{
  "id": 0,
  "name": "string",
  "key": "string",
  "filters": {},
  "deleted": true,
  "active": true,
  "created_by": {
    "id": 0,
    "uuid": "095be615-a8ad-4c33-8e9c-c7612fbf6c9f",
    "distinct_id": "string",
    "first_name": "string",
    "last_name": "string",
    "email": "user@example.com",
    "is_email_verified": true,
    "hedgehog_config": {},
    "role_at_organization": "engineering"
  },
  "created_at": "2019-08-24T14:15:22Z",
  "updated_at": "2019-08-24T14:15:22Z",
  "version": 0,
  "last_modified_by": {
    "id": 0,
    "uuid": "095be615-a8ad-4c33-8e9c-c7612fbf6c9f",
    "distinct_id": "string",
    "first_name": "string",
    "last_name": "string",
    "email": "user@example.com",
    "is_email_verified": true,
    "hedgehog_config": {},
    "role_at_organization": "engineering"
  },
  "ensure_experience_continuity": true,
  "experiment_set": [
    0
  ],
  "experiment_set_metadata": [
    {}
  ],
  "surveys": {},
  "features": {},
  "rollback_conditions": null,
  "performed_rollback": true,
  "can_edit": true,
  "tags": [
    null
  ],
  "evaluation_contexts": [
    null
  ],
  "usage_dashboard": 0,
  "analytics_dashboards": [
    0
  ],
  "has_enriched_analytics": true,
  "user_access_level": "string",
  "creation_context": "feature_flags",
  "is_remote_configuration": true,
  "has_encrypted_payloads": true,
  "status": "string",
  "evaluation_runtime": "server",
  "bucketing_identifier": "distinct_id",
  "last_called_at": "2019-08-24T14:15:22Z",
  "_create_in_folder": "string",
  "_should_create_usage_dashboard": true,
  "is_used_in_replay_settings": true
}
```

---

## Retrieve feature flags

> Also available via the [PostHog MCP server](https://posthog.com/docs/model-context-protocol):
> 
> - `feature-flag-get-definition` — Get feature flag definition

This endpoint returns a feature flag and its details like `name`, `key`, `variants`, `rollout_percentage`, and more.

To evaluate and determine the value of a flag for a given user, use the [`flags` endpoint](https://posthog.com/docs/api/flags) instead.

Create, read, update and delete feature flags. [See docs](https://posthog.com/docs/feature-flags) for more information on feature flags.

If you're looking to use feature flags on your application, you can either use our JavaScript Library or our dedicated endpoint to check if feature flags are enabled for a given user.

#### Required API key scopes

`feature_flag:read`

---

#### Path parameters

- id
	integer

---

#### Response

#### Example request

`GET ` `/api/projects/:project_id/feature_flags/:id`

```bash
export POSTHOG_PERSONAL_API_KEY=[your personal api key]
curl \
    -H "Authorization: Bearer $POSTHOG_PERSONAL_API_KEY" \
    <ph_app_host>/api/projects/:project_id/feature_flags/:id/
```

#### Example response

##### Status 200

```javascript
{
  "id": 0,
  "name": "string",
  "key": "string",
  "filters": {},
  "deleted": true,
  "active": true,
  "created_by": {
    "id": 0,
    "uuid": "095be615-a8ad-4c33-8e9c-c7612fbf6c9f",
    "distinct_id": "string",
    "first_name": "string",
    "last_name": "string",
    "email": "user@example.com",
    "is_email_verified": true,
    "hedgehog_config": {},
    "role_at_organization": "engineering"
  },
  "created_at": "2019-08-24T14:15:22Z",
  "updated_at": "2019-08-24T14:15:22Z",
  "version": 0,
  "last_modified_by": {
    "id": 0,
    "uuid": "095be615-a8ad-4c33-8e9c-c7612fbf6c9f",
    "distinct_id": "string",
    "first_name": "string",
    "last_name": "string",
    "email": "user@example.com",
    "is_email_verified": true,
    "hedgehog_config": {},
    "role_at_organization": "engineering"
  },
  "ensure_experience_continuity": true,
  "experiment_set": [
    0
  ],
  "experiment_set_metadata": [
    {}
  ],
  "surveys": {},
  "features": {},
  "rollback_conditions": null,
  "performed_rollback": true,
  "can_edit": true,
  "tags": [
    null
  ],
  "evaluation_contexts": [
    null
  ],
  "usage_dashboard": 0,
  "analytics_dashboards": [
    0
  ],
  "has_enriched_analytics": true,
  "user_access_level": "string",
  "creation_context": "feature_flags",
  "is_remote_configuration": true,
  "has_encrypted_payloads": true,
  "status": "string",
  "evaluation_runtime": "server",
  "bucketing_identifier": "distinct_id",
  "last_called_at": "2019-08-24T14:15:22Z",
  "_create_in_folder": "string",
  "_should_create_usage_dashboard": true,
  "is_used_in_replay_settings": true
}
```

---

## Update feature flags

> Also available via the [PostHog MCP server](https://posthog.com/docs/model-context-protocol):
> 
> - `update-feature-flag` — Update feature flag

Create, read, update and delete feature flags. [See docs](https://posthog.com/docs/feature-flags) for more information on feature flags.

If you're looking to use feature flags on your application, you can either use our JavaScript Library or our dedicated endpoint to check if feature flags are enabled for a given user.

#### Required API key scopes

`feature_flag:write`

---

#### Path parameters

- id
	integer

---

#### Request parameters

- key
	string
- name
	string
- filters
- active
	boolean
- tags
	array
- evaluation\_contexts
	array

---

#### Response

#### Example request

`PATCH ` `/api/projects/:project_id/feature_flags/:id`

```bash
export POSTHOG_PERSONAL_API_KEY=[your personal api key]
curl -X PATCH \
    -H "Authorization: Bearer $POSTHOG_PERSONAL_API_KEY" \
    <ph_app_host>/api/projects/:project_id/feature_flags/:id/\
    -d key="string"
```

#### Example response

##### Status 200

```javascript
{
  "id": 0,
  "name": "string",
  "key": "string",
  "filters": {},
  "deleted": true,
  "active": true,
  "created_by": {
    "id": 0,
    "uuid": "095be615-a8ad-4c33-8e9c-c7612fbf6c9f",
    "distinct_id": "string",
    "first_name": "string",
    "last_name": "string",
    "email": "user@example.com",
    "is_email_verified": true,
    "hedgehog_config": {},
    "role_at_organization": "engineering"
  },
  "created_at": "2019-08-24T14:15:22Z",
  "updated_at": "2019-08-24T14:15:22Z",
  "version": 0,
  "last_modified_by": {
    "id": 0,
    "uuid": "095be615-a8ad-4c33-8e9c-c7612fbf6c9f",
    "distinct_id": "string",
    "first_name": "string",
    "last_name": "string",
    "email": "user@example.com",
    "is_email_verified": true,
    "hedgehog_config": {},
    "role_at_organization": "engineering"
  },
  "ensure_experience_continuity": true,
  "experiment_set": [
    0
  ],
  "experiment_set_metadata": [
    {}
  ],
  "surveys": {},
  "features": {},
  "rollback_conditions": null,
  "performed_rollback": true,
  "can_edit": true,
  "tags": [
    null
  ],
  "evaluation_contexts": [
    null
  ],
  "usage_dashboard": 0,
  "analytics_dashboards": [
    0
  ],
  "has_enriched_analytics": true,
  "user_access_level": "string",
  "creation_context": "feature_flags",
  "is_remote_configuration": true,
  "has_encrypted_payloads": true,
  "status": "string",
  "evaluation_runtime": "server",
  "bucketing_identifier": "distinct_id",
  "last_called_at": "2019-08-24T14:15:22Z",
  "_create_in_folder": "string",
  "_should_create_usage_dashboard": true,
  "is_used_in_replay_settings": true
}
```

---

## Delete feature flags

> Also available via the [PostHog MCP server](https://posthog.com/docs/model-context-protocol):
> 
> - `delete-feature-flag` — Delete feature flag

Hard delete of this model is not allowed. Use a patch API call to set "deleted" to true

#### Required API key scopes

`feature_flag:write`

---

#### Path parameters

- id
	integer

---

#### Example request

`DELETE ` `/api/projects/:project_id/feature_flags/:id`

```bash
export POSTHOG_PERSONAL_API_KEY=[your personal api key]
curl  -X DELETE \
    -H "Authorization: Bearer $POSTHOG_PERSONAL_API_KEY" \
    <ph_app_host>/api/projects/:project_id/feature_flags/:id/
```

#### Example response

##### Status 405 No response body

---

## Retrieve feature flags activity

> Also available via the [PostHog MCP server](https://posthog.com/docs/model-context-protocol):
> 
> - `feature-flags-activity-retrieve` — Get feature flag activity log

Create, read, update and delete feature flags. [See docs](https://posthog.com/docs/feature-flags) for more information on feature flags.

If you're looking to use feature flags on your application, you can either use our JavaScript Library or our dedicated endpoint to check if feature flags are enabled for a given user.

#### Required API key scopes

`activity_log:read`

---

#### Path parameters

- id
	integer

---

#### Query parameters

- limit
	integer
	Default: `10`
- page
	integer
	Default: `1`

---

#### Response

#### Example request

`GET ` `/api/projects/:project_id/feature_flags/:id/activity`

```bash
export POSTHOG_PERSONAL_API_KEY=[your personal api key]
curl \
    -H "Authorization: Bearer $POSTHOG_PERSONAL_API_KEY" \
    <ph_app_host>/api/projects/:project_id/feature_flags/:id/activity/
```

#### Example response

##### Status 200

```javascript
{
  "results": [
    {
      "id": "497f6eca-6276-4993-bfeb-53cbbbba6f08",
      "user": {},
      "activity": "string",
      "scope": "string",
      "item_id": "string",
      "detail": {
        "id": "string",
        "changes": [
          {
            "type": "string",
            "action": "string",
            "field": "string",
            "before": null,
            "after": null
          }
        ],
        "merge": {
          "type": "string",
          "source": null,
          "target": null
        },
        "trigger": {
          "job_type": "string",
          "job_id": "string",
          "payload": null
        },
        "name": "string",
        "short_id": "string",
        "type": "string"
      },
      "created_at": "2019-08-24T14:15:22Z"
    }
  ],
  "next": "http://example.com",
  "previous": "http://example.com",
  "total_count": 0
}
```

##### Status 404 No response body

---

## Create feature flags create static cohort for flag

Create, read, update and delete feature flags. [See docs](https://posthog.com/docs/feature-flags) for more information on feature flags.

If you're looking to use feature flags on your application, you can either use our JavaScript Library or our dedicated endpoint to check if feature flags are enabled for a given user.

#### Path parameters

- id
	integer

---

#### Request parameters

- name
	string
- key
	string
- filters
	object
- deleted
	boolean
- active
	boolean
- created\_at
	string
- version
	integer
	Default: `0`
- ensure\_experience\_continuity
	booleannull
- rollback\_conditions
- performed\_rollback
	booleannull
- tags
	array
- evaluation\_contexts
	array
- analytics\_dashboards
	array
- has\_enriched\_analytics
	booleannull
- creation\_context
- is\_remote\_configuration
	booleannull
- has\_encrypted\_payloads
	booleannull
- evaluation\_runtime
- bucketing\_identifier
- last\_called\_at
	stringnull
- \_create\_in\_folder
	string
- \_should\_create\_usage\_dashboard
	boolean
	Default: `true`

---

#### Example request

`POST ` `/api/projects/:project_id/feature_flags/:id/create_static_cohort_for_flag`

```bash
export POSTHOG_PERSONAL_API_KEY=[your personal api key]
curl 
    -H 'Content-Type: application/json'\
    -H "Authorization: Bearer $POSTHOG_PERSONAL_API_KEY" \
    <ph_app_host>/api/projects/:project_id/feature_flags/:id/create_static_cohort_for_flag/\
    -d key="string"
```

#### Example response

##### Status 200 No response body

---

## Create feature flags dashboard

Create, read, update and delete feature flags. [See docs](https://posthog.com/docs/feature-flags) for more information on feature flags.

If you're looking to use feature flags on your application, you can either use our JavaScript Library or our dedicated endpoint to check if feature flags are enabled for a given user.

#### Path parameters

- id
	integer

---

#### Request parameters

- name
	string
- key
	string
- filters
	object
- deleted
	boolean
- active
	boolean
- created\_at
	string
- version
	integer
	Default: `0`
- ensure\_experience\_continuity
	booleannull
- rollback\_conditions
- performed\_rollback
	booleannull
- tags
	array
- evaluation\_contexts
	array
- analytics\_dashboards
	array
- has\_enriched\_analytics
	booleannull
- creation\_context
- is\_remote\_configuration
	booleannull
- has\_encrypted\_payloads
	booleannull
- evaluation\_runtime
- bucketing\_identifier
- last\_called\_at
	stringnull
- \_create\_in\_folder
	string
- \_should\_create\_usage\_dashboard
	boolean
	Default: `true`

---

#### Example request

`POST ` `/api/projects/:project_id/feature_flags/:id/dashboard`

```bash
export POSTHOG_PERSONAL_API_KEY=[your personal api key]
curl 
    -H 'Content-Type: application/json'\
    -H "Authorization: Bearer $POSTHOG_PERSONAL_API_KEY" \
    <ph_app_host>/api/projects/:project_id/feature_flags/:id/dashboard/\
    -d key="string"
```

#### Example response

##### Status 200 No response body

---

## List all feature flags dependent flags

Get other active flags that depend on this flag.

#### Required API key scopes

`feature_flag:read`

---

#### Path parameters

- id
	integer

---

#### Example request

`GET ` `/api/projects/:project_id/feature_flags/:id/dependent_flags`

```bash
export POSTHOG_PERSONAL_API_KEY=[your personal api key]
curl \
    -H "Authorization: Bearer $POSTHOG_PERSONAL_API_KEY" \
    <ph_app_host>/api/projects/:project_id/feature_flags/:id/dependent_flags/
```

#### Example response

##### Status 200

```javascript
{
  "id": 0,
  "key": "string",
  "name": "string"
}
```

---

## Create feature flags enrich usage dashboard

Create, read, update and delete feature flags. [See docs](https://posthog.com/docs/feature-flags) for more information on feature flags.

If you're looking to use feature flags on your application, you can either use our JavaScript Library or our dedicated endpoint to check if feature flags are enabled for a given user.

#### Path parameters

- id
	integer

---

#### Request parameters

- name
	string
- key
	string
- filters
	object
- deleted
	boolean
- active
	boolean
- created\_at
	string
- version
	integer
	Default: `0`
- ensure\_experience\_continuity
	booleannull
- rollback\_conditions
- performed\_rollback
	booleannull
- tags
	array
- evaluation\_contexts
	array
- analytics\_dashboards
	array
- has\_enriched\_analytics
	booleannull
- creation\_context
- is\_remote\_configuration
	booleannull
- has\_encrypted\_payloads
	booleannull
- evaluation\_runtime
- bucketing\_identifier
- last\_called\_at
	stringnull
- \_create\_in\_folder
	string
- \_should\_create\_usage\_dashboard
	boolean
	Default: `true`

---

#### Example request

`POST ` `/api/projects/:project_id/feature_flags/:id/enrich_usage_dashboard`

```bash
export POSTHOG_PERSONAL_API_KEY=[your personal api key]
curl 
    -H 'Content-Type: application/json'\
    -H "Authorization: Bearer $POSTHOG_PERSONAL_API_KEY" \
    <ph_app_host>/api/projects/:project_id/feature_flags/:id/enrich_usage_dashboard/\
    -d key="string"
```

#### Example response

##### Status 200 No response body

---

## Retrieve feature flags remote config

Create, read, update and delete feature flags. [See docs](https://posthog.com/docs/feature-flags) for more information on feature flags.

If you're looking to use feature flags on your application, you can either use our JavaScript Library or our dedicated endpoint to check if feature flags are enabled for a given user.

#### Required API key scopes

`feature_flag:read`

---

#### Path parameters

- id
	integer

---

#### Example request

`GET ` `/api/projects/:project_id/feature_flags/:id/remote_config`

```bash
export POSTHOG_PERSONAL_API_KEY=[your personal api key]
curl \
    -H "Authorization: Bearer $POSTHOG_PERSONAL_API_KEY" \
    <ph_app_host>/api/projects/:project_id/feature_flags/:id/remote_config/
```

#### Example response

##### Status 200 No response body

---

## Retrieve feature flags status

> Also available via the [PostHog MCP server](https://posthog.com/docs/model-context-protocol):
> 
> - `feature-flags-status-retrieve` — Get feature flag status

Create, read, update and delete feature flags. [See docs](https://posthog.com/docs/feature-flags) for more information on feature flags.

If you're looking to use feature flags on your application, you can either use our JavaScript Library or our dedicated endpoint to check if feature flags are enabled for a given user.

#### Required API key scopes

`feature_flag:read`

---

#### Path parameters

- id
	integer

---

#### Response

#### Example request

`GET ` `/api/projects/:project_id/feature_flags/:id/status`

```bash
export POSTHOG_PERSONAL_API_KEY=[your personal api key]
curl \
    -H "Authorization: Bearer $POSTHOG_PERSONAL_API_KEY" \
    <ph_app_host>/api/projects/:project_id/feature_flags/:id/status/
```

#### Example response

##### Status 200

```javascript
{
  "status": "string",
  "reason": "string"
}
```

---

## Create feature flags test evaluation

> Also available via the [PostHog MCP server](https://posthog.com/docs/model-context-protocol):
> 
> - `feature-flags-test-evaluation-create` — Test feature flag evaluation

Test feature flag evaluation against a specific user at an optional point in time.

This endpoint allows testing how a feature flag would evaluate for a specific user, optionally at a historical timestamp. When a timestamp is provided, both the flag conditions and person properties are evaluated as they existed at that time.

#### Required API key scopes

`feature_flag:read`

---

#### Path parameters

- id
	integer

---

#### Request parameters

- distinct\_id
	string
- person\_id
	string
- timestamp
	stringnull
- groups

---

#### Response

#### Example request

`POST ` `/api/projects/:project_id/feature_flags/:id/test_evaluation`

```bash
export POSTHOG_PERSONAL_API_KEY=[your personal api key]
curl 
    -H 'Content-Type: application/json'\
    -H "Authorization: Bearer $POSTHOG_PERSONAL_API_KEY" \
    <ph_app_host>/api/projects/:project_id/feature_flags/:id/test_evaluation/\
    -d distinct_id="string"
```

#### Example response

##### Status 200

```javascript
{
  "flag_key": "string",
  "result": null,
  "reason": "string",
  "condition_index": 0,
  "payload": null,
  "person_properties": {},
  "evaluation_distinct_id": "string",
  "conditions": [
    {
      "index": 0,
      "matched": true,
      "properties_matched": true,
      "explanation": "string",
      "rollout_percentage": 0.1,
      "rollout_excluded": true,
      "variant": "string",
      "properties": [
        {
          "key": "string",
          "operator": "string",
          "value": null,
          "type": "string",
          "actual_value": null,
          "matched": true,
          "explanation": "string"
        }
      ]
    }
  ]
}
```

##### Status 400 Invalid parameters

```javascript
{
  "error": "string"
}
```

##### Status 404 Person not found

```javascript
{
  "error": "string"
}
```

##### Status 500 Server error

```javascript
{
  "error": "string"
}
```

##### Status 502 Flag evaluation service error

```javascript
{
  "error": "string"
}
```

---

## Retrieve feature flags versions

Create, read, update and delete feature flags. [See docs](https://posthog.com/docs/feature-flags) for more information on feature flags.

If you're looking to use feature flags on your application, you can either use our JavaScript Library or our dedicated endpoint to check if feature flags are enabled for a given user.

#### Required API key scopes

`feature_flag:read`

---

#### Path parameters

- id
	integer
- version\_number
	integer

---

#### Response

#### Example request

`GET ` `/api/projects/:project_id/feature_flags/:id/versions/:version_number`

```bash
export POSTHOG_PERSONAL_API_KEY=[your personal api key]
curl \
    -H "Authorization: Bearer $POSTHOG_PERSONAL_API_KEY" \
    <ph_app_host>/api/projects/:project_id/feature_flags/:id/versions/:version_number/
```

#### Example response

##### Status 200

```javascript
{
  "id": 0,
  "key": "string",
  "name": "string",
  "filters": {},
  "active": true,
  "deleted": true,
  "version": -2147483648,
  "rollback_conditions": null,
  "performed_rollback": true,
  "ensure_experience_continuity": true,
  "has_enriched_analytics": true,
  "is_remote_configuration": true,
  "has_encrypted_payloads": true,
  "evaluation_runtime": "server",
  "bucketing_identifier": "distinct_id",
  "last_called_at": "2019-08-24T14:15:22Z",
  "created_at": "2019-08-24T14:15:22Z",
  "created_by": 0,
  "is_historical": true,
  "version_timestamp": "2019-08-24T14:15:22Z",
  "modified_by": 0
}
```

##### Status 400 Version history is not available for remote configuration flags.

##### Status 404 Version not found.

##### Status 422 Activity log incomplete; cannot reconstruct this version.

---

## Retrieve feature flags all activity

Create, read, update and delete feature flags. [See docs](https://posthog.com/docs/feature-flags) for more information on feature flags.

If you're looking to use feature flags on your application, you can either use our JavaScript Library or our dedicated endpoint to check if feature flags are enabled for a given user.

#### Required API key scopes

`activity_log:read`

---

#### Query parameters

- limit
	integer
	Default: `10`
- page
	integer
	Default: `1`

---

#### Response

#### Example request

`GET ` `/api/projects/:project_id/feature_flags/activity`

```bash
export POSTHOG_PERSONAL_API_KEY=[your personal api key]
curl \
    -H "Authorization: Bearer $POSTHOG_PERSONAL_API_KEY" \
    <ph_app_host>/api/projects/:project_id/feature_flags/activity/
```

#### Example response

##### Status 200

```javascript
{
  "results": [
    {
      "id": "497f6eca-6276-4993-bfeb-53cbbbba6f08",
      "user": {},
      "activity": "string",
      "scope": "string",
      "item_id": "string",
      "detail": {
        "id": "string",
        "changes": [
          {
            "type": "string",
            "action": "string",
            "field": "string",
            "before": null,
            "after": null
          }
        ],
        "merge": {
          "type": "string",
          "source": null,
          "target": null
        },
        "trigger": {
          "job_type": "string",
          "job_id": "string",
          "payload": null
        },
        "name": "string",
        "short_id": "string",
        "type": "string"
      },
      "created_at": "2019-08-24T14:15:22Z"
    }
  ],
  "next": "http://example.com",
  "previous": "http://example.com",
  "total_count": 0
}
```

---

## Create feature flags bulk delete

Bulk delete feature flags by filter criteria or explicit IDs.

Accepts either:

- {"filters": {...}} - Same filter params as list endpoint (search, active, type, etc.)
- {"ids": \[...\]} - Explicit list of flag IDs (no limit)

Returns same format as bulk\_delete for UI compatibility.

Uses bulk operations for efficiency: database updates are batched and cache invalidation happens once at the end rather than per-flag.

#### Required API key scopes

`feature_flag:write`

---

#### Request parameters

- filters
- ids
	array

---

#### Response

#### Example request

`POST ` `/api/projects/:project_id/feature_flags/bulk_delete`

```bash
export POSTHOG_PERSONAL_API_KEY=[your personal api key]
curl 
    -H 'Content-Type: application/json'\
    -H "Authorization: Bearer $POSTHOG_PERSONAL_API_KEY" \
    <ph_app_host>/api/projects/:project_id/feature_flags/bulk_delete/\
    -d filters=undefined
```

#### Example response

##### Status 200

```javascript
{
  "deleted": [
    {
      "id": 0,
      "key": "string",
      "rollout_state": "fully_rolled_out",
      "active_variant": "string"
    }
  ],
  "errors": [
    {
      "id": null,
      "key": "string",
      "reason": "string"
    }
  ]
}
```

##### Status 400 Invalid input — e.g., both filters and ids supplied, neither supplied, or unknown filter keys.

```javascript
{
  "error": "string"
}
```

---

## Create feature flags bulk keys

Get feature flag keys by IDs. Accepts a list of feature flag IDs and returns a mapping of ID to key.

#### Required API key scopes

`feature_flag:read`

---

#### Request parameters

- ids
	array

---

#### Response

#### Example request

`POST ` `/api/projects/:project_id/feature_flags/bulk_keys`

```bash
export POSTHOG_PERSONAL_API_KEY=[your personal api key]
curl 
    -H 'Content-Type: application/json'\
    -H "Authorization: Bearer $POSTHOG_PERSONAL_API_KEY" \
    <ph_app_host>/api/projects/:project_id/feature_flags/bulk_keys/\
    -d ids="array"
```

#### Example response

##### Status 200

```javascript
{
  "keys": {
    "property1": "string",
    "property2": "string"
  },
  "warning": "string"
}
```

##### Status 400 Invalid flag IDs provided.

```javascript
{
  "error": "string"
}
```

---

## Create feature flags bulk update tags

Bulk update tags on multiple objects.

PAT access: this action has no `required_scopes=` on the decorator — inheriting viewsets must add `"bulk_update_tags"` to their `scope_object_write_actions` list to accept personal API keys. Without that opt-in, `APIScopePermission` rejects PAT requests with "This action does not support personal API key access". Done per-viewset so granting `<scope>:write` for one resource doesn't leak access to sibling resources that share this mixin.

Accepts:

- {"ids": \[...\], "action": "add"|"remove"|"set", "tags": \["tag1", "tag2"\]}

Actions:

- "add": Add tags to existing tags on each object
- "remove": Remove specific tags from each object
- "set": Replace all tags on each object with the provided list

#### Required API key scopes

`feature_flag:write`

---

#### Request parameters

- ids
	array
- action
- tags
	array

---

#### Response

#### Example request

`POST ` `/api/projects/:project_id/feature_flags/bulk_update_tags`

```bash
export POSTHOG_PERSONAL_API_KEY=[your personal api key]
curl 
    -H 'Content-Type: application/json'\
    -H "Authorization: Bearer $POSTHOG_PERSONAL_API_KEY" \
    <ph_app_host>/api/projects/:project_id/feature_flags/bulk_update_tags/\
    -d ids="array",\
    -d action=undefined,\
    -d tags="array"
```

#### Example response

##### Status 200

```javascript
{
  "updated": [
    {
      "id": 0,
      "tags": [
        "string"
      ]
    }
  ],
  "skipped": [
    {
      "id": 0,
      "reason": "string"
    }
  ]
}
```

---

## Retrieve feature flags evaluation reasons

> Also available via the [PostHog MCP server](https://posthog.com/docs/model-context-protocol):
> 
> - `feature-flags-evaluation-reasons-retrieve` — Get feature flag evaluation reasons

Create, read, update and delete feature flags. [See docs](https://posthog.com/docs/feature-flags) for more information on feature flags.

If you're looking to use feature flags on your application, you can either use our JavaScript Library or our dedicated endpoint to check if feature flags are enabled for a given user.

#### Required API key scopes

`feature_flag:read`

---

#### Query parameters

- distinct\_id
	string
- groups
	string
	Default: `{}`

---

#### Example request

`GET ` `/api/projects/:project_id/feature_flags/evaluation_reasons`

```bash
export POSTHOG_PERSONAL_API_KEY=[your personal api key]
curl \
    -H "Authorization: Bearer $POSTHOG_PERSONAL_API_KEY" \
    <ph_app_host>/api/projects/:project_id/feature_flags/evaluation_reasons/
```

#### Example response

##### Status 200 No response body

---
title: "Feature API Reference"
site: "PostHog"
source: "https://posthog.com/docs/api/feature-flags-2"
domain: "posthog.com"
description: "The single platform for engineers to analyze, test, observe, and deploy new features. Product analytics, session replay, feature flags, experiments, CDP, and more."
word_count: 472
---

## Feature

> For instructions on how to authenticate to use this endpoint, see [API overview](https://posthog.com/docs/api/overview).

### Endpoints

| `GET` | `/api/projects/:project_id/feature_flags/local_evaluation/` |
| --- | --- |
| `GET` | `/api/projects/:project_id/feature_flags/matching_ids/` |
| `GET` | `/api/projects/:project_id/feature_flags/my_flags/` |
| `POST` | `/api/projects/:project_id/feature_flags/user_blast_radius/` |

## Retrieve feature flags local evaluation

Create, read, update and delete feature flags. [See docs](https://posthog.com/docs/feature-flags) for more information on feature flags.

If you're looking to use feature flags on your application, you can either use our JavaScript Library or our dedicated endpoint to check if feature flags are enabled for a given user.

#### Required API key scopes

`feature_flag:read`

---

#### Query parameters

- send\_cohorts
	booleannull
	Default: `false`

---

#### Response

#### Example request

`GET ` `/api/projects/:project_id/feature_flags/local_evaluation`

```bash
export POSTHOG_PERSONAL_API_KEY=[your personal api key]
curl \
    -H "Authorization: Bearer $POSTHOG_PERSONAL_API_KEY" \
    <ph_app_host>/api/projects/:project_id/feature_flags/local_evaluation/
```

#### Example response

##### Status 200

```javascript
{
  "flags": [
    {
      "id": 0,
      "team_id": 0,
      "name": "string",
      "key": "string",
      "filters": {},
      "deleted": true,
      "active": true,
      "ensure_experience_continuity": true,
      "version": -2147483648,
      "evaluation_runtime": "server",
      "bucketing_identifier": "distinct_id",
      "evaluation_contexts": [
        "string"
      ]
    }
  ],
  "group_type_mapping": {
    "property1": "string",
    "property2": "string"
  },
  "cohorts": {}
}
```

##### Status 402 Payment required

##### Status 500 Internal server error

##### Status 503 Feature flag dependencies temporarily unavailable

---

## Retrieve feature flags matching ids

Get IDs of all feature flags matching the current filters. Uses the same filtering logic as the list endpoint. Returns only IDs that the user has permission to edit.

#### Required API key scopes

`feature_flag:read`

---

#### Example request

`GET ` `/api/projects/:project_id/feature_flags/matching_ids`

```bash
export POSTHOG_PERSONAL_API_KEY=[your personal api key]
curl \
    -H "Authorization: Bearer $POSTHOG_PERSONAL_API_KEY" \
    <ph_app_host>/api/projects/:project_id/feature_flags/matching_ids/
```

#### Example response

##### Status 200 No response body

---

## Retrieve feature flags my flags

> Also available via the [PostHog MCP server](https://posthog.com/docs/model-context-protocol):
> 
> - `feature-flags-my-flags-retrieve` — Get my evaluated feature flags

Create, read, update and delete feature flags. [See docs](https://posthog.com/docs/feature-flags) for more information on feature flags.

If you're looking to use feature flags on your application, you can either use our JavaScript Library or our dedicated endpoint to check if feature flags are enabled for a given user.

#### Required API key scopes

`feature_flag:read`

---

#### Query parameters

- groups
	string
	Default: `{}`

---

#### Example request

`GET ` `/api/projects/:project_id/feature_flags/my_flags`

```bash
export POSTHOG_PERSONAL_API_KEY=[your personal api key]
curl \
    -H "Authorization: Bearer $POSTHOG_PERSONAL_API_KEY" \
    <ph_app_host>/api/projects/:project_id/feature_flags/my_flags/
```

#### Example response

##### Status 200

```javascript
{
  "feature_flag": {
    "id": 0,
    "team_id": 0,
    "name": "string",
    "key": "string",
    "filters": {},
    "deleted": true,
    "active": true,
    "ensure_experience_continuity": true,
    "version": -2147483648,
    "evaluation_runtime": "server",
    "bucketing_identifier": "distinct_id",
    "evaluation_contexts": [
      "string"
    ]
  },
  "value": null
}
```

---

## Create feature flags user blast radius

> Also available via the [PostHog MCP server](https://posthog.com/docs/model-context-protocol):
> 
> - `feature-flags-user-blast-radius-create` — Get user blast radius

Create, read, update and delete feature flags. [See docs](https://posthog.com/docs/feature-flags) for more information on feature flags.

If you're looking to use feature flags on your application, you can either use our JavaScript Library or our dedicated endpoint to check if feature flags are enabled for a given user.

#### Required API key scopes

`feature_flag:read`

---

#### Request parameters

- condition
	object
- group\_type\_index
	integernull

---

#### Response

#### Example request

`POST ` `/api/projects/:project_id/feature_flags/user_blast_radius`

```bash
export POSTHOG_PERSONAL_API_KEY=[your personal api key]
curl 
    -H 'Content-Type: application/json'\
    -H "Authorization: Bearer $POSTHOG_PERSONAL_API_KEY" \
    <ph_app_host>/api/projects/:project_id/feature_flags/user_blast_radius/\
    -d condition="object"
```

#### Example response

##### Status 200

```javascript
{
  "affected": 0,
  "total": 0
}
```
