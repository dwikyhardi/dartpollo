# **Examples**

This folder contains some examples on how to use dartpollo.

## [**pokemon**](./pokemon)

A simple example, showing [Pokémon GraphQL](https://graphql-pokemon.now.sh/) schema generation.

## [**graphqbrainz**](./graphbrainz)

A more complex example, for [graphbrainz](https://graphbrainz.herokuapp.com) (a MusicBrainz GraphQL server). Featuring union types, interfaces and custom scalars.

## [**github**](./github)

Even simpler example, for [GitHub GraphQL API](https://graphbrainz.herokuapp.com). I didn't commit the schema because it's too big (~3MB), so provide your own if you're running the example: https://github.com/octokit/graphql-schema

## [**hasura**](./hasura)

This example uses a simple [Hasura](https://hasura.io/) server (with tables schema defined [in this file](./hasura/hasura.sql)), as an example of how to use Dartpollo with subscriptions.
