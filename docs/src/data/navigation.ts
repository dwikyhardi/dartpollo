export interface NavigationItem {
  href: string;
  label: string;
}

export interface NavigationGroup {
  label: string;
  links: NavigationItem[];
}

export const navigation: NavigationGroup[] = [
  {
    label: 'Start here',
    links: [
      { href: '/', label: 'Overview' },
      { href: '/getting-started/', label: 'Getting started' },
      { href: '/mental-model/', label: 'Mental model' },
      { href: '/integration-modes/', label: 'Integration modes' },
    ],
  },
  {
    label: 'Generator',
    links: [
      { href: '/configuration/', label: 'Configuration' },
      { href: '/operations-and-variables/', label: 'Operations and variables' },
      { href: '/generated-output/', label: 'Generated output' },
      { href: '/fragments/', label: 'Fragments' },
      { href: '/graphql-features/', label: 'GraphQL features' },
      { href: '/multiple-schemas/', label: 'Multiple schemas' },
    ],
  },
  {
    label: 'Integrations',
    links: [
      { href: '/graphql-client/', label: 'package:graphql' },
      { href: '/dartpollo-client/', label: 'Dartpollo client' },
      { href: '/transport-and-links/', label: 'Transport and links' },
      { href: '/caching/', label: 'Caching' },
    ],
  },
  {
    label: 'Guides',
    links: [
      { href: '/examples/', label: 'Examples' },
      { href: '/guides/pokemon/', label: 'Pokémon tutorial' },
      { href: '/guides/github/', label: 'GitHub tutorial' },
    ],
  },
  {
    label: 'Reference',
    links: [
      { href: '/reference/generator-options/', label: 'Generator options' },
      { href: '/reference/generated-api/', label: 'Generated API' },
      { href: '/troubleshooting/', label: 'Troubleshooting' },
    ],
  },
];

export const navigationItems = navigation.flatMap((group) => group.links);
