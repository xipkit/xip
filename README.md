# <a href='https://xipkit.com'><img src='logo.svg' width='400' alt='Xip Logo' aria-label='xipkit.com' /></a>

Xip is a Ruby framework for creating text and voice chatbots. It's design is inspired by Ruby on Rails's philosophy of convention over configuration. It has an MVC architecture with the slight caveat that `views` are aptly named `replies`.

## Features

* Deploy anywhere, it's just a Rack app
* Variants allow you to use a single codebase on multiple messaging platforms
* Structured, universal reply format
* Sessions utilize a state-machine concept and are Redis backed
* Highly scalable. Incoming webhooks are processed via a Sidekiq queue
* Built-in best practices: catch-alls (error handling), hello flows, goodbye flows

## Getting Started

Getting started with Xip is simple:

```
> gem install xip
> xip new <bot>
```

## Service Integrations

Xip is extensible. All service integrations are split out into separate Ruby Gems. Things like analytics and natural language processing ([NLP](https://en.wikipedia.org/wiki/Natural-language_processing)) can be added in as gems as well.

Currently, there are gems for:

### Messaging
* [Facebook Messenger](https://github.com/xipkit/xip-facebook)
* [Twilio SMS and Whatsapp](https://github.com/xipkit/xip-twilio)

### Voice
* [Alexa Skill](https://github.com/xipkit/xip-alexa) (Early alpha)
* [Custom Voice](https://github.com/xipkit/xip-voice) (Early alpha)

### Natural Language Processing
* [LUIS](https://github.com/xipkit/xip-luis)


## Docs

You can find our full docs [here](https://docs.xipkit.com). If something is not clear in the docs, please file an issue! We consider all shortcomings in the docs as bugs.

## Versioning

Xip is versioned using [Semantic Versioning](https://semver.org). Even with major versions, though, we will strive to minimize breaking changes.

## License

Xip is licensed under the MIT license. "Xip" and the Xip Kit logo are Copyright (c) 2020 Mauricio Gomes
