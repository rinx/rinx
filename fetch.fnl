(include :cURL.impl.cURL)
(local curl (require :cURL))
(local json (require :dkjson))

(λ request [url headers body]
  (let [out []]
    (with-open [h (curl.easy)]
      (h:setopt_url url)
      (h:setopt_writefunction {:write #(table.insert out $2)})
      (h:setopt_httpheader headers)
      (h:setopt_post 1)
      (h:setopt_postfields body)
      (h:perform)
      (h:close))
    (json.decode (table.concat out "\n"))))

(λ gql-query [token query]
  (let [url "https://api.github.com/graphql"
        headers ["User-Agent: Fennel"
                 (.. "Authorization: bearer " token)]
        body (json.encode {:query query
                           :variables {:login :rinx}})]
    (request url headers body)))

(λ fetch-stargazers [token query]
  (let [result (gql-query token query)
        nodes (-?> result
                   (. :data)
                   (. :user)
                   (. :repositories)
                   (. :nodes))]
    (if nodes
      (do
        (var sum 0)
        (each [idx node (ipairs nodes)]
          (let [count (-?> node
                           (. :stargazers)
                           (. :totalCount))]
            (when count
              (set sum (+ sum count)))))
        sum)
      nil)))

(local query "query userInfo($login: String!) {
        user(login: $login) {
          name
          login
          repositories(first: 100, ownerAffiliations: OWNER, orderBy: {direction: DESC, field: STARGAZERS}) {
            totalCount
            nodes {
              stargazers {
                totalCount
              }
            }
          }
        }
      }")

(let [command (. arg 0)
      token (. arg 1)]
  (if token
    (print (fetch-stargazers token query))
    (print (.. command " [token]"))))
