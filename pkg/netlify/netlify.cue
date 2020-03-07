package netlify

import (
	"b.l/bl"
)

// A Netlify account
Account :: {
	// Use this Netlify account name
	// (also referred to as "team" in the Netlify docs)
	name: string | *""

	// Netlify authentication token
	token: bl.Secret
}

// A Netlify site
Site :: {
	// Netlify account this site is attached to
	account: Account

	// Contents of the application to deploy
	contents: bl.Directory

	// Deploy to this Netlify site
	name: string

	// Host the site at this address
	domain: string

	// Create the Netlify site if it doesn't exist?
	create: bool | *true

	// Deployment url
	url: deploy.output["/info/url"]

	deploy: bl.BashScript & {

		workdir: "/site/contents"
		input: "/site/contents": contents
		input: "/account/token": account.token

		output: "/info/url": string

		environment: {
			NETLIFY_SITE_NAME: name
			if (create) {
				NETLIFY_SITE_CREATE: "1"
			}
			NETLIFY_DOMAIN:  domain
			NETLIFY_ACCOUNT: account.name
		}

		os: {
			package: {
				yarn:  true
				curl:  true
				jq:    true
				rsync: true
			}
			extraCommand: [
				"yarn global add netlify-cli",
			]
		}

		code: #"""
			account_token="$(cat /account/token)"
			create_site() {
			    # FIXME: This doesn't enable HTTPS on the site.
			    url="https://api.netlify.com/api/v1/${NETLIFY_ACCOUNT:-}/sites"

			    response=$(curl -f -H "Authorization: Bearer $account_token" \
			                -X POST -H "Content-Type: application/json" \
			                $url \
			                -d '{"subdomain": "$NETLIFY_SITE_NAME", "custom_domain": "$NETLIFY_DOMAIN"}'
			            )
			    [ $? -ne 0 ] && echo "create site failed" && exit 1

			    echo $response | jq -r '.site_id'
			}

			site_id=$(curl -f -H "Authorization: Bearer $account_token" \
			            https://api.netlify.com/api/v1/sites\?filter\=all | \
			            jq -r ".[] | select(.name==\"$NETLIFY_SITE_NAME\") | .id" \
			        )
			if [ -z "$site_id" ] ; then
			    if [ "${NETLIFY_SITE_CREATE:-}" != 1 ]; then
			        echo "Site $NETLIFY_SITE_NAME does not exist"
			        exit 1
			    fi
			    site_id=$(create_site)
			fi
			netlify deploy \
			    --dir="$(pwd)" \
			    --auth="$account_token" \
			    --site="$site_id" \
			    --message="Blocklayer 'netlify deploy'" \
			    --prod \
			| tee /tmp/stdout

			# enable SSL
			curl -i -X POST "https://api.netlify.com/api/v1/sites/${site_id}/ssl"

			# FIXME: parent directory of an output should be created automatically,
			# for convenience.
			mkdir -p /info
			</tmp/stdout sed -n -e 's/^Live URL:.*\(https:\/\/.*\)$/\1/p' > /info/url
			"""#
	}
}
